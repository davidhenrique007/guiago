import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/dashboard/application/next_level_progress.dart';
import 'package:guiago/features/performance/domain/level.dart';
import 'package:guiago/features/performance/domain/level_policy.dart';

void main() {
  const LevelPolicy policy = LevelPolicy.defaultPolicy;

  NextLevelGap? gap(LevelTier tier, int score) =>
      NextLevelProgress.calculate(current: tier, score: score, policy: policy);

  test('points to the next threshold and progress between the two', () {
    final NextLevelGap result = gap(LevelTier.consistent, 150)!;

    expect(result.tier, LevelTier.disciplined);
    expect(result.points, 150); // 300 - 150
    expect(result.progress, closeTo(0.25, 1e-9)); // (150-100)/(300-100)
  });

  test('a score of zero is the whole distance away', () {
    final NextLevelGap result = gap(LevelTier.beginner, 0)!;

    expect(result.tier, LevelTier.consistent);
    expect(result.points, 100);
    expect(result.progress, 0);
  });

  test('elite has nothing after it', () {
    expect(gap(LevelTier.elite, 5000), isNull);
  });

  test('exactly on the next threshold shows nothing (0 points)', () {
    expect(gap(LevelTier.consistent, 300), isNull);
  });

  test('score above the next threshold shows nothing', () {
    expect(gap(LevelTier.consistent, 450), isNull);
  });

  test('a negative score counts from below the current threshold', () {
    final NextLevelGap result = gap(LevelTier.beginner, -20)!;

    expect(result.points, 120);
    expect(result.progress, 0); // clamped
  });
}
