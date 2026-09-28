// GuiaGo — Fase 5: Performance Engine + Gamification
// ScoringPolicy (secção 19 da master spec)
//
// "Nunca espalhar números pelo código." Toda a pontuação passa
// por esta política única, facilmente alterável sem tocar no
// ScoreEngine.

import 'score.dart';

class ScoringPolicy {
  const ScoringPolicy({
    this.points = const {
      ScoringReason.completed: 10,
      ScoringReason.completedAfterSnooze: 5,
      ScoringReason.missed: -5,
      ScoringReason.declined: -5,
    },
  });

  final Map<ScoringReason, int> points;

  int pointsFor(ScoringReason reason) => points[reason] ?? 0;

  static const ScoringPolicy defaultPolicy = ScoringPolicy();
}
