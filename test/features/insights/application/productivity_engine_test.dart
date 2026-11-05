import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/insights/application/productivity_engine.dart';
import 'package:guiago/features/insights/domain/insights_policy.dart';
import 'package:guiago/features/insights/domain/insights_snapshot.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';

void main() {
  const ProductivityEngine engine = ProductivityEngine();

  TaskOccurrence completedAt(DateTime? completed, {DateTime? scheduled}) {
    return TaskOccurrence(
      id: 'o-${completed?.microsecondsSinceEpoch}-${scheduled?.hour}',
      taskId: 't',
      scheduledAt: scheduled ?? DateTime(2026, 3, 1, 6),
      completedAt: completed,
      status: OccurrenceStatus.completed,
      snoozeCount: 0,
      toleranceMinutes: 15,
    );
  }

  /// [counts] maps hour -> number of completions at that hour.
  List<int> histogramOf(Map<int, int> counts) {
    final List<int> h = List<int>.filled(24, 0);
    counts.forEach((hour, n) => h[hour] = n);
    return h;
  }

  group('histogram', () {
    test('has 24 entries and counts by completion hour', () {
      final List<int> h = engine.histogram(<TaskOccurrence>[
        completedAt(DateTime(2026, 3, 1, 8, 5)),
        completedAt(DateTime(2026, 3, 2, 8, 55)),
        completedAt(DateTime(2026, 3, 2, 14, 0)),
      ]);

      expect(h, hasLength(24));
      expect(h[8], 2);
      expect(h[14], 1);
      expect(h.fold<int>(0, (a, b) => a + b), 3);
    });

    test('midnight boundaries fall in hours 0 and 23', () {
      final List<int> h = engine.histogram(<TaskOccurrence>[
        completedAt(DateTime(2026, 3, 1, 0, 0)),
        completedAt(DateTime(2026, 3, 1, 23, 59, 59)),
      ]);

      expect(h[0], 1);
      expect(h[23], 1);
    });

    test('falls back to scheduledAt when completedAt is missing', () {
      final List<int> h = engine.histogram(<TaskOccurrence>[
        completedAt(null, scheduled: DateTime(2026, 3, 1, 17, 30)),
      ]);

      expect(h[17], 1);
    });
  });

  group('peak', () {
    test('finds the three consecutive hours with most completions', () {
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{8: 3, 9: 4, 10: 3, 15: 2}),
      );

      expect(peak, const ProductivityPeak(startHour: 8, endHour: 10));
    });

    test('the window may start before the busiest hour', () {
      // Busiest hour is 11, but 9-11 beats 11-13 only if sums say so.
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{9: 3, 10: 3, 11: 4, 20: 1}),
      );

      expect(peak, const ProductivityPeak(startHour: 9, endHour: 11));
    });

    test('a tie goes to the earliest window', () {
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{6: 5, 18: 5}),
      );

      expect(peak, const ProductivityPeak(startHour: 4, endHour: 6));
    });

    test('too few completions gives no peak', () {
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{8: 9}), // 9 < default minimum of 10
      );

      expect(peak, isNull);
    });

    test('exactly the minimum is enough', () {
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{8: 10}),
      );

      expect(peak, isNotNull);
    });

    test('late evening window stays inside the day', () {
      final ProductivityPeak? peak = engine.peak(
        histogramOf(<int, int>{23: 12}),
      );

      expect(peak, const ProductivityPeak(startHour: 21, endHour: 23));
    });

    test('the minimum comes from the policy', () {
      const ProductivityEngine strict = ProductivityEngine(
        policy: InsightsPolicy(minCompletions: 3),
      );

      expect(strict.peak(histogramOf(<int, int>{8: 3})), isNotNull);
    });
  });
}
