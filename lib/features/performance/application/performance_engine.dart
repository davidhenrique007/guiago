// GuiaGo — Fase 5: Performance Engine + Gamification
// PerformanceEngine (secção 18 da master spec)
//
// Função pura: recebe outcomes de um período, devolve um
// PerformanceRecord. Sem I/O, sem SQLite, sem Flutter — por isso
// não usa Result<T> aqui (não há falha de infraestrutura
// possível; lista vazia é um caso válido, não um erro).

import '../domain/occurrence_outcome.dart';
import '../domain/performance_record.dart';

class PerformanceEngine {
  const PerformanceEngine();

  PerformanceRecord calculate({
    required String id,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<OccurrenceOutcome> outcomes,
    required DateTime calculatedAt,
  }) {
    assert(
      !periodEnd.isBefore(periodStart),
      'periodEnd não pode ser anterior a periodStart',
    );

    final total = outcomes.length;

    if (total == 0) {
      return PerformanceRecord(
        id: id,
        periodStart: periodStart,
        periodEnd: periodEnd,
        totalOccurrences: 0,
        completedCount: 0,
        completedAfterSnoozeCount: 0,
        missedCount: 0,
        declinedCount: 0,
        snoozedCount: 0,
        completionRate: 0,
        missRate: 0,
        snoozeRate: 0,
        averageResponseTime: null,
        calculatedAt: calculatedAt,
      );
    }

    final completed =
        outcomes.where((o) => o.status == OutcomeStatus.completed).toList();
    final completedAfterSnooze =
        completed.where((o) => o.snoozeCount > 0).toList();
    final missed =
        outcomes.where((o) => o.status == OutcomeStatus.missed).toList();
    final declined =
        outcomes.where((o) => o.status == OutcomeStatus.declined).toList();
    final snoozed = outcomes.where((o) => o.snoozeCount > 0).toList();

    final responseTimes =
        outcomes.map((o) => o.responseTime).whereType<Duration>().toList();

    final averageResponseTime = responseTimes.isEmpty
        ? null
        : Duration(
            microseconds: responseTimes.fold<int>(
                  0,
                  (sum, d) => sum + d.inMicroseconds,
                ) ~/
                responseTimes.length,
          );

    return PerformanceRecord(
      id: id,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalOccurrences: total,
      completedCount: completed.length,
      completedAfterSnoozeCount: completedAfterSnooze.length,
      missedCount: missed.length,
      declinedCount: declined.length,
      snoozedCount: snoozed.length,
      completionRate: completed.length / total,
      missRate: missed.length / total,
      snoozeRate: snoozed.length / total,
      averageResponseTime: averageResponseTime,
      calculatedAt: calculatedAt,
    );
  }
}
