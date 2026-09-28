import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/data/occurrence_outcome_mapper.dart';
import 'package:guiago/features/performance/domain/day_outcome.dart';
import 'package:guiago/features/performance/domain/occurrence_outcome.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';

void main() {
  const mapper = OccurrenceOutcomeMapper();

  TaskOccurrence occurrence({
    required String id,
    required OccurrenceStatus status,
    DateTime? scheduledAt,
    int snoozeCount = 0,
    Duration? responseTime,
  }) {
    return TaskOccurrence(
      id: id,
      taskId: 't1',
      scheduledAt: scheduledAt ?? DateTime(2026, 1, 1, 9),
      status: status,
      snoozeCount: snoozeCount,
      responseTime: responseTime,
      toleranceMinutes: 15,
    );
  }

  group('OccurrenceOutcomeMapper.toOutcome', () {
    test('maps terminal statuses', () {
      expect(
        mapper
            .toOutcome(
                occurrence(id: 'o1', status: OccurrenceStatus.completed),)!
            .status,
        OutcomeStatus.completed,
      );
      expect(
        mapper
            .toOutcome(occurrence(id: 'o2', status: OccurrenceStatus.missed))!
            .status,
        OutcomeStatus.missed,
      );
      expect(
        mapper
            .toOutcome(occurrence(id: 'o3', status: OccurrenceStatus.declined))!
            .status,
        OutcomeStatus.declined,
      );
    });

    test('returns null for non-terminal and cancelled statuses', () {
      for (final status in [
        OccurrenceStatus.scheduled,
        OccurrenceStatus.triggered,
        OccurrenceStatus.snoozed,
        OccurrenceStatus.cancelled,
      ]) {
        expect(
          mapper.toOutcome(occurrence(id: 'o', status: status)),
          isNull,
          reason: '$status should not map to an OccurrenceOutcome',
        );
      }
    });

    test('carries snoozeCount and responseTime through', () {
      final outcome = mapper.toOutcome(
        occurrence(
          id: 'o1',
          status: OccurrenceStatus.completed,
          snoozeCount: 2,
          responseTime: const Duration(minutes: 5),
        ),
      )!;

      expect(outcome.snoozeCount, 2);
      expect(outcome.responseTime, const Duration(minutes: 5));
    });
  });

  group('OccurrenceOutcomeMapper.toOutcomes', () {
    test('filters out non-terminal occurrences, keeping order', () {
      final result = mapper.toOutcomes([
        occurrence(id: 'o1', status: OccurrenceStatus.completed),
        occurrence(id: 'o2', status: OccurrenceStatus.scheduled),
        occurrence(id: 'o3', status: OccurrenceStatus.missed),
      ]);

      expect(result.map((o) => o.occurrenceId), ['o1', 'o3']);
    });
  });

  group('OccurrenceOutcomeMapper.toDayOutcomes', () {
    final rangeStart = DateTime(2026, 1, 1);
    final rangeEnd = DateTime(2026, 1, 3);

    test('a day with no occurrences is neutral', () {
      final days = mapper.toDayOutcomes(
        occurrences: const [],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        today: DateTime(2026, 1, 5),
      );

      expect(days, hasLength(3));
      expect(
        days.every((d) => d.fulfillment == DayFulfillment.neutral),
        isTrue,
      );
    });

    test('a day where everything completed is fulfilled', () {
      final days = mapper.toDayOutcomes(
        occurrences: [
          occurrence(
            id: 'o1',
            status: OccurrenceStatus.completed,
            scheduledAt: DateTime(2026, 1, 1, 9),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        today: DateTime(2026, 1, 5),
      );

      final day1 = days.firstWhere((d) => d.date == DateTime(2026, 1, 1));
      expect(day1.fulfillment, DayFulfillment.fulfilled);
    });

    test('a day with a miss among terminated occurrences is broken', () {
      final days = mapper.toDayOutcomes(
        occurrences: [
          occurrence(
            id: 'o1',
            status: OccurrenceStatus.completed,
            scheduledAt: DateTime(2026, 1, 1, 9),
          ),
          occurrence(
            id: 'o2',
            status: OccurrenceStatus.missed,
            scheduledAt: DateTime(2026, 1, 1, 18),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        today: DateTime(2026, 1, 5),
      );

      final day1 = days.firstWhere((d) => d.date == DateTime(2026, 1, 1));
      expect(day1.fulfillment, DayFulfillment.broken);
    });

    test('a day with only cancelled occurrences is neutral, not broken', () {
      final days = mapper.toDayOutcomes(
        occurrences: [
          occurrence(
            id: 'o1',
            status: OccurrenceStatus.cancelled,
            scheduledAt: DateTime(2026, 1, 1, 9),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        today: DateTime(2026, 1, 5),
      );

      final day1 = days.firstWhere((d) => d.date == DateTime(2026, 1, 1));
      expect(day1.fulfillment, DayFulfillment.neutral);
    });

    test('today is neutral while it still has unresolved occurrences', () {
      final today = DateTime(2026, 1, 2);
      final days = mapper.toDayOutcomes(
        occurrences: [
          occurrence(
            id: 'o1',
            status: OccurrenceStatus.completed,
            scheduledAt: DateTime(2026, 1, 2, 9),
          ),
          occurrence(
            id: 'o2',
            status: OccurrenceStatus.scheduled,
            scheduledAt: DateTime(2026, 1, 2, 20),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        today: today,
      );

      final todayOutcome = days.firstWhere((d) => d.date == today);
      expect(todayOutcome.fulfillment, DayFulfillment.neutral);
    });
  });
}
