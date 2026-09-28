// GuiaGo — Fase 5: Performance Engine + Gamification
// DayOutcome
//
// DEFINIÇÃO DE "DIA CUMPRIDO" (secção 21 exige documentar isto —
// formalizar em docs/adr/ADR-007-streak-definition.md):
//
//   fulfilled — houve pelo menos 1 ocorrência agendada nesse dia
//               E todas terminaram em COMPLETED.
//   broken    — houve pelo menos 1 ocorrência agendada nesse dia
//               E pelo menos uma terminou em MISSED ou DECLINED.
//   neutral   — não havia nenhuma ocorrência agendada nesse dia.
//               Não quebra nem estende a sequência (dias "livres"
//               não penalizam o streak).
//
// O dia corrente (hoje), enquanto ainda tiver ocorrências por
// resolver, não deve ser mapeado como "broken" prematuramente —
// isso é responsabilidade de quem constrói a lista de DayOutcome
// (mapper/Repository na camada de Data), não deste modelo.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_outcome.freezed.dart';

enum DayFulfillment { fulfilled, neutral, broken }

@freezed
sealed class DayOutcome with _$DayOutcome {
  const factory DayOutcome({
    /// Data normalizada à meia-noite local (sem componente de hora).
    required DateTime date,
    required DayFulfillment fulfillment,
  }) = _DayOutcome;
}
