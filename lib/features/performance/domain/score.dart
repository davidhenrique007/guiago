// GuiaGo — Fase 5: Performance Engine + Gamification
// Entidades de domínio: ScoringReason, ScoreEntry, Score
//
// Modelo em estilo "event ledger": cada ação pontuável gera um
// ScoreEntry imutável (auditável, nunca editado). O Score é o
// agregado (total corrente), reconstruível a partir dos entries.
// Consistente com o padrão já usado em TaskEvent (Fase 2).
//
// Sem userId: app é single-user local. Score é um agregado único
// (single-row na tabela, mesmo padrão do SettingsTable).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'score.freezed.dart';

/// Motivo pelo qual uma ocorrência gerou pontos.
///
/// Nota: `completedAfterSnooze` não é um estado da máquina de
/// estados (secção 11) — é derivado quando uma TaskOccurrence
/// termina em COMPLETED mas com snoozeCount > 0. Essa derivação
/// é responsabilidade do ScoreEngine, não desta entidade.
enum ScoringReason {
  completed,
  completedAfterSnooze,
  missed,
  declined,
}

@freezed
sealed class ScoreEntry with _$ScoreEntry {
  const factory ScoreEntry({
    required String id,
    required String occurrenceId,
    required ScoringReason reason,
    required int points,
    required DateTime occurredAt,
  }) = _ScoreEntry;
}

@freezed
sealed class Score with _$Score {
  const Score._();

  const factory Score({
    required int total,
    required DateTime updatedAt,
  }) = _Score;

  Score applyEntry(ScoreEntry entry) {
    return copyWith(
      total: total + entry.points,
      updatedAt: entry.occurredAt,
    );
  }
}
