import 'package:freezed_annotation/freezed_annotation.dart';

import '../../performance/domain/level.dart';
import '../../performance/domain/performance_record.dart';
import '../../performance/domain/score.dart';
import '../../performance/domain/streak_status.dart';
import 'dashboard_period.dart';
import 'trend_point.dart';

part 'dashboard_snapshot.freezed.dart';

/// Everything the dashboard screen needs for one [period], already
/// calculated — the UI never computes metrics (master spec §3, Fase 6).
@freezed
sealed class DashboardSnapshot with _$DashboardSnapshot {
  const factory DashboardSnapshot({
    required DashboardPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,

    /// Metrics for the period, computed in memory (never persisted).
    required PerformanceRecord performance,

    /// One point per day of the period, zero-filled.
    required List<TrendPoint> trend,

    /// Persisted, all-time values.
    required Score score,
    LevelStatus? level,
    StreakStatus? streak,

    /// The tier after the current one, and how far away it is. Both
    /// null when there is nothing to show (top tier, or the level is
    /// held back by recent performance) — see `NextLevelProgress`.
    LevelTier? nextTier,
    int? pointsToNextTier,

    /// 0.0–1.0 position between the current and the next threshold.
    double? nextTierProgress,
  }) = _DashboardSnapshot;
}
