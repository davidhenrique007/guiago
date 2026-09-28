// GuiaGo — Fase 5: Performance Engine + Gamification
// LevelEngine (secção 20 da master spec)

import '../domain/level.dart';
import '../domain/level_policy.dart';
import '../domain/performance_record.dart';

class LevelEngine {
  const LevelEngine({this.policy = LevelPolicy.defaultPolicy});

  final LevelPolicy policy;

  /// [id] é gerado pelo chamador (uuid), consistente com o padrão
  /// já usado nas fases anteriores. [recentPerformance] deve cobrir
  /// uma janela curta (ex.: últimos 7 ou 14 dias) — é o que impede
  /// um score alto e antigo de manter alguém em ELITE se o
  /// desempenho recente caiu.
  LevelStatus evaluate({
    required String id,
    required int totalScore,
    required LevelTier previousTier,
    required PerformanceRecord recentPerformance,
    required DateTime evaluatedAt,
  }) {
    var tier = policy.tierForScore(totalScore);

    final belowFloor = !recentPerformance.isEmpty &&
        recentPerformance.completionRate < policy.recentCompletionRateFloor;

    if (belowFloor && tier.rank > LevelTier.beginner.rank) {
      tier = LevelTier.values[tier.rank - 1];
    }

    return LevelStatus(
      id: id,
      tier: tier,
      previousTier: previousTier,
      scoreAtEvaluation: totalScore,
      evaluatedAt: evaluatedAt,
    );
  }
}
