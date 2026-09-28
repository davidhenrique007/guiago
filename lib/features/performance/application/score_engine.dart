// GuiaGo — Fase 5: Performance Engine + Gamification
// ScoreEngine (secção 19 da master spec)
//
// Deriva o ScoringReason de cada outcome terminado, consulta a
// ScoringPolicy para os pontos, e produz/aplica ScoreEntry.
// Também é uma função pura — a persistência do ledger e do
// agregado Score fica para o Repository.

import '../domain/occurrence_outcome.dart';
import '../domain/score.dart';
import '../domain/scoring_policy.dart';

class ScoreEngine {
  const ScoreEngine({this.policy = ScoringPolicy.defaultPolicy});

  final ScoringPolicy policy;

  ScoringReason reasonFor(OccurrenceOutcome outcome) {
    switch (outcome.status) {
      case OutcomeStatus.completed:
        return outcome.snoozeCount > 0
            ? ScoringReason.completedAfterSnooze
            : ScoringReason.completed;
      case OutcomeStatus.missed:
        return ScoringReason.missed;
      case OutcomeStatus.declined:
        return ScoringReason.declined;
    }
  }

  /// Gera o ScoreEntry correspondente a um outcome já terminado.
  /// `id` é gerado pelo chamador (uuid), consistente com o padrão
  /// já usado nas fases anteriores.
  ScoreEntry entryFor({
    required String id,
    required OccurrenceOutcome outcome,
    required DateTime occurredAt,
  }) {
    final reason = reasonFor(outcome);
    return ScoreEntry(
      id: id,
      occurrenceId: outcome.occurrenceId,
      reason: reason,
      points: policy.pointsFor(reason),
      occurredAt: occurredAt,
    );
  }

  /// Reconstrói o total de um Score aplicando uma lista de
  /// entries em ordem cronológica. Útil para recomputar o
  /// agregado a partir do ledger (ex.: após correção de dados).
  Score applyAll(Score current, List<ScoreEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return sorted.fold(current, (score, entry) => score.applyEntry(entry));
  }
}
