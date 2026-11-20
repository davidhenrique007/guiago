import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../scheduler/application/scheduler_engine.dart';
import '../../tasks/application/task_engine.dart';
import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../domain/overdue_classifier.dart';
import '../domain/recovery_action.dart';
import '../domain/recovery_policy.dart';
import '../domain/recovery_report.dart';

/// Fase 7 — Reliability + Offline Recovery.
///
/// Reconciles what the database says with what the phone will actually
/// do. Runs when the app starts and when it returns to the foreground,
/// because alarms can be lost while the app is not running (reboot,
/// force-stop, revoked permission, a failed scheduling call that
/// `TaskEngine` deliberately ignores).
///
/// Two phases:
/// 1. Catch-up: occurrences whose tolerance window already closed are
///    resolved as missed, always through [TaskEngine] (the only place
///    allowed to change an occurrence's status). Because each resolved
///    recurring occurrence generates the next one, this repeats until
///    nothing overdue is left.
/// 2. Re-arm: every live occurrence that is still actionable gets its
///    alarm (re)armed — future ones normally, overdue ones still inside
///    their tolerance window right away.
class RecoveryService {
  RecoveryService({
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskEngine taskEngine,
    required SchedulerEngine scheduler,
    DateTime Function()? clock,
  })  : _occurrences = occurrenceRepository,
        _taskEngine = taskEngine,
        _scheduler = scheduler,
        _clock = clock ?? DateTime.now;

  final TaskOccurrenceRepository _occurrences;
  final TaskEngine _taskEngine;
  final SchedulerEngine _scheduler;
  final DateTime Function() _clock;

  bool _running = false;

  /// [excludeOccurrenceId] is the occurrence the user is opening right
  /// now (app launched from its notification): recovery leaves it alone
  /// so it does not race with the alarm screen.
  Future<Result<RecoveryReport>> run({String? excludeOccurrenceId}) async {
    if (_running) {
      return const Success<RecoveryReport>(RecoveryReport.empty);
    }
    _running = true;
    try {
      return await _run(excludeOccurrenceId);
    } finally {
      _running = false;
    }
  }

  Future<Result<RecoveryReport>> _run(String? excludeId) async {
    final DateTime now = _clock();
    final List<Failure> failures = <Failure>[];
    final Set<String> unresolved = <String>{};
    int markedMissed = 0;

    // Phase 1 — catch-up.
    for (int pass = 0; pass < RecoveryPolicy.maxCatchUpPasses; pass++) {
      final Result<List<TaskOccurrence>> activeResult =
          await _occurrences.getAllActiveOccurrences();
      if (activeResult case Fail<List<TaskOccurrence>>(:final failure)) {
        return Fail<RecoveryReport>(failure);
      }

      final List<TaskOccurrence> expired = activeResult.valueOrNull!
          .where(
            (TaskOccurrence o) =>
                o.id != excludeId &&
                !unresolved.contains(o.id) &&
                OverdueClassifier.classify(o, now) == RecoveryAction.markMissed,
          )
          .toList();
      if (expired.isEmpty) break;

      int resolvedInPass = 0;
      for (final TaskOccurrence occurrence in expired) {
        final Result<TaskOccurrence> result = await _expire(occurrence);
        switch (result) {
          case Success<TaskOccurrence>():
            markedMissed++;
            resolvedInPass++;
          case Fail<TaskOccurrence>(:final failure):
            failures.add(failure);
            unresolved.add(occurrence.id);
        }
      }
      if (resolvedInPass == 0) break;
    }

    // Phase 2 — re-arm what is still actionable.
    final Result<List<TaskOccurrence>> liveResult =
        await _occurrences.getAllActiveOccurrences();
    if (liveResult case Fail<List<TaskOccurrence>>(:final failure)) {
      return Fail<RecoveryReport>(failure);
    }

    int rescheduled = 0;
    int surfaced = 0;
    for (final TaskOccurrence occurrence in liveResult.valueOrNull!) {
      if (occurrence.id == excludeId) continue;
      switch (OverdueClassifier.classify(occurrence, now)) {
        case RecoveryAction.reschedule:
          {
            final Result<void> result = await _scheduler.reschedule(occurrence);
            if (result case Fail<void>(:final failure)) {
              failures.add(failure);
            } else {
              rescheduled++;
            }
          }
        case RecoveryAction.surfaceNow:
          {
            // Only the notification moves; the occurrence keeps its
            // original `scheduledAt` in the database.
            final Result<void> result = await _scheduler.scheduleOccurrence(
              occurrence.copyWith(
                scheduledAt: now.add(RecoveryPolicy.surfaceDelay),
              ),
            );
            if (result case Fail<void>(:final failure)) {
              failures.add(failure);
            } else {
              surfaced++;
            }
          }
        case RecoveryAction.markMissed:
          // Left over from phase 1 (a failure or the pass limit):
          // the next run retries.
          break;
        case RecoveryAction.leaveAsIs:
          break;
      }
    }

    return Success<RecoveryReport>(
      RecoveryReport(
        rescheduled: rescheduled,
        surfaced: surfaced,
        markedMissed: markedMissed,
        failures: List<Failure>.unmodifiable(failures),
      ),
    );
  }

  /// `scheduled → missed` is not a valid transition (§11): the alarm
  /// moment is treated as the trigger, then the occurrence misses.
  Future<Result<TaskOccurrence>> _expire(TaskOccurrence occurrence) async {
    if (occurrence.status == OccurrenceStatus.scheduled) {
      final Result<TaskOccurrence> triggered =
          await _taskEngine.triggerOccurrence(occurrence.id);
      if (triggered case Fail<TaskOccurrence>()) return triggered;
    }
    return _taskEngine.markMissed(occurrence.id);
  }
}
