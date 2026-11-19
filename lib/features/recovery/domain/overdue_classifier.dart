import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task_occurrence.dart';
import 'recovery_action.dart';

/// Pure rule: given a live occurrence and "now", what should recovery
/// do with it? No I/O, so every edge case is unit-testable.
abstract final class OverdueClassifier {
  static RecoveryAction classify(TaskOccurrence occurrence, DateTime now) {
    return switch (occurrence.status) {
      // A snoozed occurrence goes back to `scheduled` with a new
      // `scheduledAt`, so its old `triggeredAt` must NOT be used here.
      OccurrenceStatus.scheduled => occurrence.scheduledAt.isAfter(now)
          ? RecoveryAction.reschedule
          : _windowAction(
              occurrence.scheduledAt,
              occurrence.toleranceMinutes,
              now,
            ),
      OccurrenceStatus.triggered => _windowAction(
          occurrence.triggeredAt ?? occurrence.scheduledAt,
          occurrence.toleranceMinutes,
          now,
        ),
      OccurrenceStatus.snoozed ||
      OccurrenceStatus.completed ||
      OccurrenceStatus.declined ||
      OccurrenceStatus.missed ||
      OccurrenceStatus.cancelled =>
        RecoveryAction.leaveAsIs,
    };
  }

  static RecoveryAction _windowAction(
    DateTime base,
    int toleranceMinutes,
    DateTime now,
  ) {
    final DateTime deadline = base.add(Duration(minutes: toleranceMinutes));
    return now.isAfter(deadline)
        ? RecoveryAction.markMissed
        : RecoveryAction.surfaceNow;
  }
}
