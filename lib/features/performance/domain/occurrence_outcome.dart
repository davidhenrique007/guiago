// GuiaGo — Fase 5: Performance Engine + Gamification
// OccurrenceOutcome
//
// Input mínimo de que o PerformanceEngine e o ScoreEngine
// precisam, desacoplado da entidade TaskOccurrence concreta da
// feature "tasks". O domínio desta fase não deve importar outra
// feature diretamente — quem faz o mapeamento
// TaskOccurrence -> OccurrenceOutcome é o mapper na camada de
// Data (ver data/mappers/), que já conhece as duas features.
//
// Só ocorrências TERMINADAS entram aqui: COMPLETED, MISSED,
// DECLINED. Ocorrências CANCELLED (tarefa apagada/arquivada
// antes do prazo) não devem ser mapeadas — não contam para
// desempenho nem pontuação.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'occurrence_outcome.freezed.dart';

enum OutcomeStatus { completed, missed, declined }

@freezed
sealed class OccurrenceOutcome with _$OccurrenceOutcome {
  const factory OccurrenceOutcome({
    required String occurrenceId,
    required OutcomeStatus status,
    required int snoozeCount,

    /// Tempo entre TRIGGERED e a ação final do utilizador.
    /// Null se não houver registo (ex.: MISSED sem interação).
    Duration? responseTime,
  }) = _OccurrenceOutcome;
}
