import '../../performance/domain/level.dart';
import '../../performance/domain/level_policy.dart';

/// Distance from the current level to the next one.
typedef NextLevelGap = ({LevelTier tier, int points, double progress});

/// Pure rule behind "Faltam X pontos para o próximo nível".
///
/// Returns null (the UI then shows nothing) when:
/// - [current] is already the top tier, or
/// - the score already reaches the next threshold, which happens when
///   the level is held back by recent performance
///   (`LevelPolicy.recentCompletionRateFloor`) — saying "faltam 0
///   pontos" would be misleading.
abstract final class NextLevelProgress {
  static NextLevelGap? calculate({
    required LevelTier current,
    required int score,
    required LevelPolicy policy,
  }) {
    final int nextRank = current.rank + 1;
    if (nextRank >= LevelTier.values.length) return null;

    final LevelTier next = LevelTier.values[nextRank];
    final int nextThreshold = policy.scoreThresholds[next]!;
    final int currentThreshold = policy.scoreThresholds[current]!;

    final int points = nextThreshold - score;
    if (points <= 0) return null;

    final int span = nextThreshold - currentThreshold;
    final double progress =
        span <= 0 ? 0 : ((score - currentThreshold) / span).clamp(0.0, 1.0);

    return (tier: next, points: points, progress: progress);
  }
}
