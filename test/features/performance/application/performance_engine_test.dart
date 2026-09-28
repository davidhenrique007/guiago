import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/application/performance_engine.dart';
import 'package:guiago/features/performance/domain/occurrence_outcome.dart';

void main() {
  const engine = PerformanceEngine();

  group('PerformanceEngine.calculate', () {
    test('returns an empty record when there are no outcomes', () {
      final record = engine.calculate(
        id: 'r1',
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 1, 23, 59, 59),
        outcomes: const [],
        calculatedAt: DateTime(2026, 1, 2),
      );

      expect(record.isEmpty, isTrue);
      expect(record.totalOccurrences, 0);
      expect(record.completionRate, 0);
      expect(record.missRate, 0);
      expect(record.snoozeRate, 0);
      expect(record.averageResponseTime, isNull);
    });

    test('computes counts and rates for a mix of outcomes', () {
      final outcomes = [
        const OccurrenceOutcome(
          occurrenceId: 'o1',
          status: OutcomeStatus.completed,
          snoozeCount: 0,
          responseTime: Duration(minutes: 2),
        ),
        const OccurrenceOutcome(
          occurrenceId: 'o2',
          status: OutcomeStatus.completed,
          snoozeCount: 1,
          responseTime: Duration(minutes: 4),
        ),
        const OccurrenceOutcome(
          occurrenceId: 'o3',
          status: OutcomeStatus.missed,
          snoozeCount: 0,
        ),
        const OccurrenceOutcome(
          occurrenceId: 'o4',
          status: OutcomeStatus.declined,
          snoozeCount: 0,
        ),
      ];

      final record = engine.calculate(
        id: 'r2',
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 1, 23, 59, 59),
        outcomes: outcomes,
        calculatedAt: DateTime(2026, 1, 2),
      );

      expect(record.totalOccurrences, 4);
      expect(record.completedCount, 2);
      expect(record.completedAfterSnoozeCount, 1);
      expect(record.missedCount, 1);
      expect(record.declinedCount, 1);
      expect(record.snoozedCount, 1);
      expect(record.completionRate, 0.5);
      expect(record.missRate, 0.25);
      expect(record.snoozeRate, 0.25);
      expect(record.averageResponseTime, const Duration(minutes: 3));
    });

    test('ignores outcomes without a responseTime when averaging', () {
      final outcomes = [
        const OccurrenceOutcome(
          occurrenceId: 'o1',
          status: OutcomeStatus.completed,
          snoozeCount: 0,
          responseTime: Duration(minutes: 10),
        ),
        const OccurrenceOutcome(
          occurrenceId: 'o2',
          status: OutcomeStatus.missed,
          snoozeCount: 0,
        ),
      ];

      final record = engine.calculate(
        id: 'r3',
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 1, 23, 59, 59),
        outcomes: outcomes,
        calculatedAt: DateTime(2026, 1, 2),
      );

      expect(record.averageResponseTime, const Duration(minutes: 10));
    });

    test('rejects a period where end precedes start', () {
      expect(
        () => engine.calculate(
          id: 'r4',
          periodStart: DateTime(2026, 1, 2),
          periodEnd: DateTime(2026, 1, 1),
          outcomes: const [],
          calculatedAt: DateTime(2026, 1, 2),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
