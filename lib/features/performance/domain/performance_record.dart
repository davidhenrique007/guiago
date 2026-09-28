// GuiaGo — Fase 5: Performance Engine + Gamification
// Entidade de domínio: PerformanceRecord
//
// Representa o resultado agregado de desempenho do utilizador
// para uma janela de tempo (ex.: dia, semana, mês).
//
// Esta entidade é o OUTPUT do PerformanceEngine (ver secção 18
// da master spec). Não contém lógica de cálculo — é um valor
// imutável, puro, sem dependências de Flutter, SQLite ou IA.
//
// Sem userId: app é single-user local (mesmo padrão de Task,
// TaskOccurrence e AlarmRecord no schema real).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance_record.freezed.dart';

@freezed
sealed class PerformanceRecord with _$PerformanceRecord {
  const PerformanceRecord._();

  const factory PerformanceRecord({
    required String id,

    /// Janela temporal a que este registo se refere.
    required DateTime periodStart,
    required DateTime periodEnd,

    /// Contagens brutas (fonte de verdade para as taxas abaixo).
    required int totalOccurrences,
    required int completedCount,
    required int completedAfterSnoozeCount,
    required int missedCount,
    required int declinedCount,
    required int snoozedCount,

    /// Taxas derivadas, sempre no intervalo [0.0, 1.0].
    required double completionRate,
    required double missRate,
    required double snoozeRate,

    /// Tempo médio de resposta entre o disparo do alarme (TRIGGERED)
    /// e a ação do utilizador (COMPLETED/SNOOZED/DECLINED).
    /// Null quando não há ocorrências com resposta registada.
    Duration? averageResponseTime,
    required DateTime calculatedAt,
  }) = _PerformanceRecord;

  /// Verdadeiro se não houve nenhuma ocorrência nesta janela —
  /// útil para a UI decidir entre AppEmptyState e os dados reais.
  bool get isEmpty => totalOccurrences == 0;
}
