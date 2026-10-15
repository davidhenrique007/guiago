import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/features/dashboard/application/dashboard_service.dart';
import 'package:guiago/features/dashboard/application/trend_engine.dart';
import 'package:guiago/features/dashboard/domain/dashboard_period.dart';
import 'package:guiago/features/performance/application/performance_engine.dart';
import 'package:guiago/features/performance/data/occurrence_outcome_mapper.dart';
import 'package:guiago/features/performance/domain/level.dart';
import 'package:guiago/features/performance/domain/score.dart';
import 'package:guiago/features/performance/domain/streak_status.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';

import '../../performance/support/in_memory_repositories.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 15, 12);

  late InMemoryTaskOccurrenceRepository occurrences;
  late InMemoryScoreRepository scores;
  late InMemoryLevelRepository levels;
  late InMemoryStreakRepository streaks;
  late DashboardService service;

  TaskOccurrence occurrence(
    String id,
    OccurrenceStatus status,
    DateTime scheduledAt, {
    Duration? responseTime,
  }) {
    return TaskOccurrence(
      id: id,
      taskId: 't1',
      scheduledAt: scheduledAt,
      status: status,
      snoozeCount: 0,
      responseTime: responseTime,
      toleranceMinutes: 15,
    );
  }

  setUp(() {
    occurrences = InMemoryTaskOccurrenceRepository();
    scores = InMemoryScoreRepository();
    levels = InMemoryLevelRepository();
    streaks = InMemoryStreakRepository();
    service = DashboardService(
      occurrenceRepository: occurrences,
      mapper: const OccurrenceOutcomeMapper(),
      performanceEngine: const PerformanceEngine(),
      trendEngine: const TrendEngine(),
      scoreRepository: scores,
      levelRepository: levels,
      streakRepository: streaks,
    );
  });

  group('DashboardService.load', () {
    test('returns an empty, zero-filled snapshot when there is no data',
        () async {
      final result = await service.load(DashboardPeriod.week, now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.performance.isEmpty, isTrue);
      expect(snapshot.trend, hasLength(7));
      expect(snapshot.trend.every((p) => !p.hasData), isTrue);
      expect(snapshot.score.total, 0);
      expect(snapshot.level, isNull);
      expect(snapshot.streak, isNull);
    });

    test('computes today metrics and ignores unfinished occurrences', () async {
      await occurrences.saveOccurrence(
        occurrence(
          'a',
          OccurrenceStatus.completed,
          DateTime(2026, 3, 15, 9),
          responseTime: const Duration(minutes: 2),
        ),
      );
      await occurrences.saveOccurrence(
        occurrence('b', OccurrenceStatus.missed, DateTime(2026, 3, 15, 10)),
      );
      await occurrences.saveOccurrence(
        occurrence('c', OccurrenceStatus.scheduled, DateTime(2026, 3, 15, 18)),
      );

      final result = await service.load(DashboardPeriod.today, now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.performance.totalOccurrences, 2);
      expect(snapshot.performance.completedCount, 1);
      expect(snapshot.performance.completionRate, 0.5);
      expect(snapshot.performance.missRate, 0.5);
      expect(
        snapshot.performance.averageResponseTime,
        const Duration(minutes: 2),
      );
      expect(snapshot.trend.single.total, 2);
      expect(snapshot.trend.single.completed, 1);
    });

    test('week window includes its first day and excludes older ones',
        () async {
      await occurrences.saveOccurrence(
        occurrence('old', OccurrenceStatus.completed, DateTime(2026, 3, 7, 9)),
      );
      await occurrences.saveOccurrence(
        occurrence(
          'first',
          OccurrenceStatus.completed,
          DateTime(2026, 3, 9, 9),
        ),
      );
      await occurrences.saveOccurrence(
        occurrence(
          'today',
          OccurrenceStatus.completed,
          DateTime(2026, 3, 15, 9),
        ),
      );

      final result = await service.load(DashboardPeriod.week, now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.performance.totalOccurrences, 2);
      expect(snapshot.trend, hasLength(7));
      expect(snapshot.trend.first.day, DateTime(2026, 3, 9));
      expect(snapshot.trend.first.total, 1);
      expect(snapshot.trend.last.day, DateTime(2026, 3, 15));
      expect(snapshot.trend.last.total, 1);
    });

    test('includes the persisted score, level and streak', () async {
      scores.score = Score(total: 30, updatedAt: now);
      await levels.saveEvaluation(
        LevelStatus(
          id: 'l1',
          tier: LevelTier.consistent,
          previousTier: LevelTier.beginner,
          scoreAtEvaluation: 120,
          evaluatedAt: now,
        ),
      );
      streaks.status = StreakStatus(
        currentStreak: 3,
        longestStreak: 5,
        calculatedAt: now,
      );

      final result = await service.load(DashboardPeriod.today, now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.score.total, 30);
      expect(snapshot.level?.tier, LevelTier.consistent);
      expect(snapshot.streak?.currentStreak, 3);
      expect(snapshot.streak?.longestStreak, 5);
    });

    test('never writes anything', () async {
      await occurrences.saveOccurrence(
        occurrence('a', OccurrenceStatus.completed, DateTime(2026, 3, 15, 9)),
      );

      await service.load(DashboardPeriod.month, now: now);

      expect(scores.entries, isEmpty);
      expect(levels.items, isEmpty);
      expect(streaks.status, isNull);
    });

    test('propagates a repository failure', () async {
      occurrences.rangeFailure = const DatabaseFailure('boom');

      final result = await service.load(DashboardPeriod.today, now: now);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });
}
