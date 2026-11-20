import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/recovery/domain/overdue_classifier.dart';
import 'package:guiago/features/recovery/domain/recovery_action.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 15, 12);

  TaskOccurrence occurrence({
    required OccurrenceStatus status,
    required DateTime scheduledAt,
    DateTime? triggeredAt,
    int toleranceMinutes = 15,
  }) {
    return TaskOccurrence(
      id: 'o1',
      taskId: 't1',
      scheduledAt: scheduledAt,
      triggeredAt: triggeredAt,
      status: status,
      snoozeCount: 0,
      toleranceMinutes: toleranceMinutes,
    );
  }

  group('OverdueClassifier.classify', () {
    test('a scheduled occurrence in the future is rescheduled', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.scheduled,
        scheduledAt: now.add(const Duration(hours: 1)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.reschedule);
    });

    test(
        'a scheduled occurrence past its time but inside tolerance is '
        'surfaced now', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.scheduled,
        scheduledAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.surfaceNow);
    });

    test('a scheduled occurrence past its tolerance is marked missed', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.scheduled,
        scheduledAt: now.subtract(const Duration(minutes: 16)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.markMissed);
    });

    test('exactly at the end of the tolerance it is still surfaced', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.scheduled,
        scheduledAt: now.subtract(const Duration(minutes: 15)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.surfaceNow);
    });

    test('a triggered occurrence counts its tolerance from triggeredAt', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.triggered,
        scheduledAt: now.subtract(const Duration(hours: 2)),
        triggeredAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.surfaceNow);
    });

    test('a triggered occurrence past its tolerance is marked missed', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.triggered,
        scheduledAt: now.subtract(const Duration(hours: 2)),
        triggeredAt: now.subtract(const Duration(hours: 1)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.markMissed);
    });

    test('a snoozed-then-scheduled occurrence ignores its old triggeredAt', () {
      final TaskOccurrence o = occurrence(
        status: OccurrenceStatus.scheduled,
        scheduledAt: now.add(const Duration(minutes: 10)),
        triggeredAt: now.subtract(const Duration(hours: 3)),
      );

      expect(OverdueClassifier.classify(o, now), RecoveryAction.reschedule);
    });

    test('terminal and transient statuses are left alone', () {
      for (final OccurrenceStatus status in <OccurrenceStatus>[
        OccurrenceStatus.completed,
        OccurrenceStatus.declined,
        OccurrenceStatus.missed,
        OccurrenceStatus.cancelled,
        OccurrenceStatus.snoozed,
      ]) {
        final TaskOccurrence o = occurrence(
          status: status,
          scheduledAt: now.subtract(const Duration(days: 1)),
        );

        expect(
          OverdueClassifier.classify(o, now),
          RecoveryAction.leaveAsIs,
          reason: '$status',
        );
      }
    });
  });
}
