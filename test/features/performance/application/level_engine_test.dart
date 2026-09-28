import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/application/level_engine.dart';
import 'package:guiago/features/performance/domain/level.dart';
import 'package:guiago/features/performance/domain/performance_record.dart';

void main() {
  const engine = LevelEngine();

  PerformanceRecord recordWithRate(double completionRate, {int total = 10}) {
    final completed = (completionRate * total).round();
    return PerformanceRecord(
      id: 'p1',
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 7),
      totalOccurrences: total,
      completedCount: completed,
      completedAfterSnoozeCount: 0,
      missedCount: total - completed,
      declinedCount: 0,
      snoozedCount: 0,
      completionRate: completionRate,
      missRate: 1 - completionRate,
      snoozeRate: 0,
      averageResponseTime: null,
      calculatedAt: DateTime(2026, 1, 7),
    );
  }

  final emptyRecord = PerformanceRecord(
    id: 'p0',
    periodStart: DateTime(2026, 1, 1),
    periodEnd: DateTime(2026, 1, 7),
    totalOccurrences: 0,
    completedCount: 0,
    completedAfterSnoozeCount: 0,
    missedCount: 0,
    declinedCount: 0,
    snoozedCount: 0,
    completionRate: 0,
    missRate: 0,
    snoozeRate: 0,
    averageResponseTime: null,
    calculatedAt: DateTime(2026, 1, 7),
  );

  group('LevelEngine.evaluate', () {
    test(
      'picks the tier matching the score when recent performance is good',
      () {
        final status = engine.evaluate(
          id: 'l1',
          totalScore: 750,
          previousTier: LevelTier.disciplined,
          recentPerformance: recordWithRate(0.9),
          evaluatedAt: DateTime(2026, 1, 7),
        );

        expect(status.tier, LevelTier.elite);
        expect(status.previousTier, LevelTier.disciplined);
        expect(status.scoreAtEvaluation, 750);
      },
    );

    test(
      'downgrades one tier when recent completion rate is below the floor',
      () {
        final status = engine.evaluate(
          id: 'l2',
          totalScore: 750,
          previousTier: LevelTier.elite,
          recentPerformance: recordWithRate(0.3),
          evaluatedAt: DateTime(2026, 1, 7),
        );

        expect(status.tier, LevelTier.disciplined);
      },
    );

    test('never downgrades below beginner', () {
      final status = engine.evaluate(
        id: 'l3',
        totalScore: 10,
        previousTier: LevelTier.beginner,
        recentPerformance: recordWithRate(0.1),
        evaluatedAt: DateTime(2026, 1, 7),
      );

      expect(status.tier, LevelTier.beginner);
    });

    test('does not penalize when there is no recent data', () {
      final status = engine.evaluate(
        id: 'l4',
        totalScore: 750,
        previousTier: LevelTier.elite,
        recentPerformance: emptyRecord,
        evaluatedAt: DateTime(2026, 1, 7),
      );

      expect(status.tier, LevelTier.elite);
    });
  });
}
