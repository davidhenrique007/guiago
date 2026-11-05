import '../../../core/result/result.dart';
import '../../performance/application/performance_engine.dart';
import '../../performance/data/occurrence_outcome_mapper.dart';
import '../../performance/domain/level.dart';
import '../../performance/domain/level_policy.dart';
import '../../performance/domain/level_repository.dart';
import '../../performance/domain/occurrence_outcome.dart';
import '../../performance/domain/score_repository.dart';
import '../../performance/domain/streak_repository.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../domain/dashboard_period.dart';
import '../domain/dashboard_snapshot.dart';
import 'next_level_progress.dart';
import 'trend_engine.dart';

/// Read-only assembler of a [DashboardSnapshot].
///
/// Period metrics and the trend are computed in memory from the
/// occurrences of the period; Score, Level and Streak are read from
/// what `PerformanceController` already persisted. Opening the
/// dashboard therefore never writes to the database.
class DashboardService {
  DashboardService({
    required TaskOccurrenceRepository occurrenceRepository,
    required OccurrenceOutcomeMapper mapper,
    required PerformanceEngine performanceEngine,
    required TrendEngine trendEngine,
    required ScoreRepository scoreRepository,
    required LevelRepository levelRepository,
    required StreakRepository streakRepository,
    LevelPolicy policy = LevelPolicy.defaultPolicy,
  })  : _policy = policy,
        _occurrences = occurrenceRepository,
        _mapper = mapper,
        _performanceEngine = performanceEngine,
        _trendEngine = trendEngine,
        _scores = scoreRepository,
        _levels = levelRepository,
        _streaks = streakRepository;

  final TaskOccurrenceRepository _occurrences;
  final OccurrenceOutcomeMapper _mapper;
  final PerformanceEngine _performanceEngine;
  final TrendEngine _trendEngine;
  final ScoreRepository _scores;
  final LevelRepository _levels;
  final StreakRepository _streaks;
  final LevelPolicy _policy;

  /// [now] exists only so tests can pin the clock.
  Future<Result<DashboardSnapshot>> load(
    DashboardPeriod period, {
    DateTime? now,
  }) async {
    final DateTime clock = now ?? DateTime.now();
    final DashboardRange range = period.rangeAt(clock);

    final occurrencesResult =
        await _occurrences.getOccurrencesInRange(range.start, range.end);
    if (occurrencesResult.isFailure) {
      return Fail<DashboardSnapshot>(occurrencesResult.failureOrNull!);
    }

    final scoreResult = await _scores.getScore();
    if (scoreResult.isFailure) {
      return Fail<DashboardSnapshot>(scoreResult.failureOrNull!);
    }
    final levelResult = await _levels.getLatest();
    if (levelResult.isFailure) {
      return Fail<DashboardSnapshot>(levelResult.failureOrNull!);
    }
    final streakResult = await _streaks.getStatus();
    if (streakResult.isFailure) {
      return Fail<DashboardSnapshot>(streakResult.failureOrNull!);
    }

    final Map<DateTime, List<OccurrenceOutcome>> byDay =
        <DateTime, List<OccurrenceOutcome>>{};
    for (final TaskOccurrence occurrence in occurrencesResult.valueOrNull!) {
      final OccurrenceOutcome? outcome = _mapper.toOutcome(occurrence);
      if (outcome == null) continue; // not finished, or cancelled
      final DateTime day = DateTime(
        occurrence.scheduledAt.year,
        occurrence.scheduledAt.month,
        occurrence.scheduledAt.day,
      );
      byDay.putIfAbsent(day, () => <OccurrenceOutcome>[]).add(outcome);
    }

    final LevelStatus? level = levelResult.valueOrNull;
    final NextLevelGap? gap = NextLevelProgress.calculate(
      current: level?.tier ?? LevelTier.beginner,
      score: scoreResult.valueOrNull!.total,
      policy: _policy,
    );

    return Success<DashboardSnapshot>(
      DashboardSnapshot(
        period: period,
        rangeStart: range.start,
        rangeEnd: range.end,
        performance: _performanceEngine.calculate(
          id: 'dashboard-${period.name}',
          periodStart: range.start,
          periodEnd: range.end,
          outcomes: byDay.values.expand((l) => l).toList(),
          calculatedAt: clock,
        ),
        trend: _trendEngine.calculate(
          rangeStart: range.start,
          rangeEnd: range.end,
          outcomesByDay: byDay,
        ),
        score: scoreResult.valueOrNull!,
        level: level,
        streak: streakResult.valueOrNull,
        nextTier: gap?.tier,
        pointsToNextTier: gap?.points,
        nextTierProgress: gap?.progress,
      ),
    );
  }
}
