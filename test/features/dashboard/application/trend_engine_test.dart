import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/dashboard/application/trend_engine.dart';
import 'package:guiago/features/performance/domain/occurrence_outcome.dart';

void main() {
  const TrendEngine engine = TrendEngine();

  OccurrenceOutcome outcome(String id, OutcomeStatus status) {
    return OccurrenceOutcome(
      occurrenceId: id,
      status: status,
      snoozeCount: 0,
    );
  }

  group('TrendEngine.calculate', () {
    test('returns one zeroed point per day when there is no data', () {
      final points = engine.calculate(
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 3, 3, 23, 59),
        outcomesByDay: const <DateTime, List<OccurrenceOutcome>>{},
      );

      expect(points, hasLength(3));
      expect(points.map((p) => p.day), [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ]);
      expect(points.every((p) => !p.hasData), isTrue);
    });

    test('counts total and completed per day', () {
      final points = engine.calculate(
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
        outcomesByDay: <DateTime, List<OccurrenceOutcome>>{
          DateTime(2026, 3, 2): <OccurrenceOutcome>[
            outcome('a', OutcomeStatus.completed),
            outcome('b', OutcomeStatus.missed),
            outcome('c', OutcomeStatus.completed),
            outcome('d', OutcomeStatus.declined),
          ],
        },
      );

      expect(points.first.total, 0);
      expect(points.last.total, 4);
      expect(points.last.completed, 2);
      expect(points.last.completionRate, 0.5);
    });

    test('completionRate is 0 for a day without occurrences', () {
      final points = engine.calculate(
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 3, 1, 23, 59),
        outcomesByDay: const <DateTime, List<OccurrenceOutcome>>{},
      );

      expect(points.single.completionRate, 0);
    });
  });
}
