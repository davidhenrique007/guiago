// GuiaGo — hook opcional para a Fase 5 (Performance/Gamification)
//
// Mesmo padrão de dependency-inversion do AlarmScheduler (ADR-006):
// tasks/ define a interface, outra feature implementa-a, e o
// TaskEngine chama-a sem nunca importar essa feature diretamente.
//
// Best-effort por desenho: implementações NUNCA devem lançar —
// o TaskEngine não bloqueia nem falha a operação principal por
// causa disto (ver chamada em _resolveOccurrence).

import 'task_occurrence.dart';

abstract interface class OccurrenceOutcomeRecorder {
  Future<void> onOccurrenceResolved(TaskOccurrence occurrence);
}
