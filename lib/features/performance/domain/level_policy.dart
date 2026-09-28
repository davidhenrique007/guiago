// GuiaGo — Fase 5: Performance Engine + Gamification
// LevelPolicy
//
// Valores por defeito, arbitrários — ajusta livremente. Formaliza
// a versão final em docs/adr (mesmo espírito da ScoringPolicy,
// secção 19: nunca espalhar estes números pelo código).
//
// Regra (secção 20): o nível não depende só do score histórico.
// `recentCompletionRateFloor` é o mecanismo que faz isso — se a
// completionRate recente cair abaixo disto, o tier é limitado a
// um nível abaixo do que o score, sozinho, indicaria.

import 'level.dart';

class LevelPolicy {
  const LevelPolicy({
    this.scoreThresholds = const {
      LevelTier.elite: 700,
      LevelTier.disciplined: 300,
      LevelTier.consistent: 100,
      LevelTier.beginner: 0,
    },
    this.recentCompletionRateFloor = 0.5,
  });

  final Map<LevelTier, int> scoreThresholds;
  final double recentCompletionRateFloor;

  static const LevelPolicy defaultPolicy = LevelPolicy();

  LevelTier tierForScore(int score) {
    if (score >= scoreThresholds[LevelTier.elite]!) return LevelTier.elite;
    if (score >= scoreThresholds[LevelTier.disciplined]!) {
      return LevelTier.disciplined;
    }
    if (score >= scoreThresholds[LevelTier.consistent]!) {
      return LevelTier.consistent;
    }
    return LevelTier.beginner;
  }
}
