import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../scheduler/data/scheduler_providers.dart';
import '../../tasks/application/task_engine.dart';
import '../../tasks/data/task_providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../domain/decline_reason.dart';
import '../domain/tolerance_checker.dart';
import 'alarm_providers.dart';

/// What the alarm screen needs to render, and whether the user has
/// already resolved it (so the screen knows to close itself).
class AlarmRingUiState {
  const AlarmRingUiState({
    required this.task,
    required this.occurrence,
    required this.isResolved,
  });

  final Task task;
  final TaskOccurrence occurrence;
  final bool isResolved;

  AlarmRingUiState copyWith({TaskOccurrence? occurrence, bool? isResolved}) {
    return AlarmRingUiState(
      task: task,
      occurrence: occurrence ?? this.occurrence,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

/// Drives the alarm-ringing experience for one occurrence (master
/// spec §4/§24): marks it TRIGGERED, speaks the task aloud via TTS,
/// arms an automatic MISS once the tolerance window closes, and
/// forwards the user's Concluída/Adiar/Não-vou choice to [TaskEngine].
///
/// The occurrence ID is a "family" argument. Riverpod 3.0 removed
/// `FamilyAsyncNotifier`/`build(arg)` — family notifiers now receive
/// their argument via the constructor instead, and read it back from
/// a field inside `build()`.
class AlarmRingController extends AsyncNotifier<AlarmRingUiState> {
  AlarmRingController(this.occurrenceId);

  final String occurrenceId;

  Timer? _missTimer;

  @override
  Future<AlarmRingUiState> build() async {
    ref.onDispose(() => _missTimer?.cancel());

    final TaskEngine taskEngine = ref.watch(taskEngineWithSchedulerProvider);
    final taskRepository = ref.watch(taskRepositoryProvider);

    final Result<TaskOccurrence> triggerResult =
        await taskEngine.triggerOccurrence(occurrenceId);
    TaskOccurrence? occurrence = triggerResult.valueOrNull;

    // Re-opening the screen on an already-TRIGGERED occurrence is not
    // an error — just load it as-is instead of re-triggering.
    if (occurrence == null) {
      occurrence = (await ref
              .read(taskOccurrenceRepositoryProvider)
              .getOccurrence(occurrenceId))
          .valueOrNull;
    }
    if (occurrence == null) {
      throw StateError('Occurrence $occurrenceId not found');
    }

    final Task? task =
        (await taskRepository.getTask(occurrence.taskId)).valueOrNull;
    if (task == null) {
      throw StateError('Task ${occurrence.taskId} not found');
    }

    await ref.read(ttsServiceProvider).speak(task.title);
    _armMissTimer(occurrence);

    return AlarmRingUiState(
      task: task,
      occurrence: occurrence,
      isResolved: false,
    );
  }

  void _armMissTimer(TaskOccurrence occurrence) {
    final Duration remaining = ToleranceChecker.remaining(
      triggeredAt: occurrence.triggeredAt ?? DateTime.now(),
      toleranceMinutes: occurrence.toleranceMinutes,
      now: DateTime.now(),
    );
    if (remaining.isNegative) {
      unawaited(_resolve(() => _engine.markMissed(occurrence.id)));
      return;
    }
    _missTimer = Timer(remaining, () {
      unawaited(_resolve(() => _engine.markMissed(occurrence.id)));
    });
  }

  Future<void> complete() {
    _missTimer?.cancel();
    final String currentOccurrenceId = _currentState!.occurrence.id;
    return _resolve(() => _engine.completeOccurrence(currentOccurrenceId));
  }

  Future<void> decline(DeclineReason reason) {
    _missTimer?.cancel();
    final String currentOccurrenceId = _currentState!.occurrence.id;
    return _resolve(
      () => _engine.declineOccurrence(
        currentOccurrenceId,
        reason: reason.label,
      ),
    );
  }

  Future<void> snooze() {
    _missTimer?.cancel();
    final String currentOccurrenceId = _currentState!.occurrence.id;
    return _resolve(() => _engine.snoozeOccurrence(currentOccurrenceId));
  }

  TaskEngine get _engine => ref.read(taskEngineWithSchedulerProvider);

  /// `AsyncValue.valueOrNull` was removed in Riverpod 3.0 — this is
  /// the pattern-matching replacement used throughout this project
  /// (see `OnboardingController` from Fase 1) since it doesn't
  /// depend on exactly which convenience getter the installed
  /// version does or doesn't have.
  AlarmRingUiState? get _currentState => switch (state) {
        AsyncData<AlarmRingUiState>(:final value) => value,
        _ => null,
      };

  Future<void> _resolve(
    Future<Result<TaskOccurrence>> Function() action,
  ) async {
    final Result<TaskOccurrence> result = await action();
    final AlarmRingUiState? current = _currentState;
    if (current == null) return;
    if (result.isSuccess) {
      state = AsyncData<AlarmRingUiState>(current.copyWith(isResolved: true));
    }
  }
}

final alarmRingControllerProvider =
    AsyncNotifierProvider.family<AlarmRingController, AlarmRingUiState, String>(
  AlarmRingController.new,
);
