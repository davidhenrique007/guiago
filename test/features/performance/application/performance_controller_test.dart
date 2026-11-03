import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/application/level_engine.dart';
import 'package:guiago/features/performance/application/performance_controller.dart';
import 'package:guiago/features/performance/application/performance_engine.dart';
import 'package:guiago/features/performance/application/score_engine.dart';
import 'package:guiago/features/performance/application/streak_engine.dart';
import 'package:guiago/features/performance/data/occurrence_outcome_mapper.dart';
import 'package:guiago/features/performance/domain/level.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';

import '../support/in_memory_repositories.dart';

void main() {
  late InMemoryTaskOccurrenceRepository occurrences;
  late InMemoryScoreRepository scores;
  late InMemoryLevelRepository levels;
  late InMemoryStreakRepository streaks;
  late InMemoryPerformanceRecordRepository records;
  late PerformanceController controller;

  TaskOccurrence occurrence(
    String id,
    OccurrenceStatus status,
    DateTime scheduledAt,
  ) {
    return TaskOccurrence(
      id: id,
      taskId: 't1',
      scheduledAt: scheduledAt,
      status: status,
      snoozeCount: 0,
      toleranceMinutes: 15,
    );
  }

  DateTime daysAgo(int days) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days, 9);
  }

  setUp(() {
    occurrences = InMemoryTaskOccurrenceRepository();
    scores = InMemoryScoreRepository();
    levels = InMemoryLevelRepository();
    streaks = InMemoryStreakRepository();
    records = InMemoryPerformanceRecordRepository();
    controller = PerformanceController(
      occurrenceRepository: occurrences,
      mapper: const OccurrenceOutcomeMapper(),
      performanceEngine: const PerformanceEngine(),
      scoreEngine: const ScoreEngine(),
      levelEngine: const LevelEngine(),
      streakEngine: const StreakEngine(),
      performanceRecordRepository: records,
      scoreRepository: scores,
      levelRepository: levels,
      streakRepository: streaks,
    );
  });

  group('PerformanceController.onOccurrenceResolved', () {
    test('scores, updates the streak and evaluates the level', () async {
      final completed = occurrence(
        'o1',
        OccurrenceStatus.completed,
        DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await occurrences.saveOccurrence(completed);

      await controller.onOccurrenceResolved(completed);

      expect(scores.score.total, 10);
      expect(scores.entries, hasLength(1));
      expect(streaks.status?.currentStreak, 1);
      expect(levels.items, hasLength(1));
      expect(levels.items.single.tier, LevelTier.beginner);
    });

    test('does not create performance records (no duplicates per event)',
        () async {
      final completed = occurrence(
        'o1',
        OccurrenceStatus.completed,
        DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await occurrences.saveOccurrence(completed);

      await controller.onOccurrenceResolved(completed);

      expect(records.items, isEmpty);
    });

    test('only records level CHANGES, not every evaluation', () async {
      final first = occurrence(
        'o1',
        OccurrenceStatus.completed,
        DateTime.now().subtract(const Duration(minutes: 2)),
      );
      final second = occurrence(
        'o2',
        OccurrenceStatus.completed,
        DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await occurrences.saveOccurrence(first);
      await occurrences.saveOccurrence(second);

      await controller.onOccurrenceResolved(first);
      await controller.onOccurrenceResolved(second);

      expect(scores.score.total, 20);
      expect(levels.items, hasLength(1));
    });
  });

  group('PerformanceController.recordOutcome', () {
    test('ignores an occurrence that has not finished', () async {
      final pending = occurrence(
        'o1',
        OccurrenceStatus.scheduled,
        DateTime.now(),
      );

      final result = await controller.recordOutcome(pending);

      expect(result.valueOrNull?.total, 0);
      expect(scores.entries, isEmpty);
    });
  });

  group('PerformanceController.recalculatePerformance', () {
    test('persists exactly one record with the period metrics', () async {
      await occurrences.saveOccurrence(
        occurrence('a', OccurrenceStatus.completed, daysAgo(0)),
      );
      await occurrences.saveOccurrence(
        occurrence('b', OccurrenceStatus.missed, daysAgo(0)),
      );

      final result = await controller.recalculatePerformance(
        periodStart: daysAgo(1),
        periodEnd: daysAgo(-1),
      );

      expect(result.isSuccess, isTrue);
      expect(records.items, hasLength(1));
      expect(records.items.single.totalOccurrences, 2);
      expect(records.items.single.completedCount, 1);
      expect(records.items.single.missedCount, 1);
    });
  });

  group('PerformanceController.recalculateStreak', () {
    test('without rangeStart it uses the full history', () async {
      // Missed long ago, then 3 completed days in a row ending yesterday.
      await occurrences.saveOccurrence(
        occurrence('old', OccurrenceStatus.missed, daysAgo(200)),
      );
      await occurrences.saveOccurrence(
        occurrence('d3', OccurrenceStatus.completed, daysAgo(3)),
      );
      await occurrences.saveOccurrence(
        occurrence('d2', OccurrenceStatus.completed, daysAgo(2)),
      );
      await occurrences.saveOccurrence(
        occurrence('d1', OccurrenceStatus.completed, daysAgo(1)),
      );

      final DateTime now = DateTime.now();
      final result = await controller.recalculateStreak(
        rangeEnd: now,
        today: now,
      );

      expect(result.valueOrNull?.currentStreak, 3);
      expect(result.valueOrNull?.longestStreak, 3);
      expect(streaks.status?.currentStreak, 3);
    });

    test('with no occurrences the streak is zero', () async {
      final DateTime now = DateTime.now();

      final result = await controller.recalculateStreak(
        rangeEnd: now,
        today: now,
      );

      expect(result.valueOrNull?.currentStreak, 0);
      expect(result.valueOrNull?.longestStreak, 0);
    });
  });
}
