// GuiaGo — Fase 5: Performance Engine + Gamification
// OccurrenceOutcomeMapper
//
// Único ponto do projeto onde a feature "performance" conhece a
// feature "tasks". Converte TaskOccurrence (Fase 2) nos modelos
// que os engines desta fase consomem — mantendo o domain/ de
// performance sem depender de outra feature (secção 5).

import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../domain/day_outcome.dart';
import '../domain/occurrence_outcome.dart';

class OccurrenceOutcomeMapper {
  const OccurrenceOutcomeMapper();

  /// Mapeia uma TaskOccurrence terminada para OccurrenceOutcome.
  /// Devolve null para ocorrências não terminadas (SCHEDULED,
  /// TRIGGERED, SNOOZED) ou CANCELLED — estas não entram nas
  /// métricas de desempenho nem na pontuação.
  OccurrenceOutcome? toOutcome(TaskOccurrence occurrence) {
    final status = _mapStatus(occurrence.status);
    if (status == null) return null;

    return OccurrenceOutcome(
      occurrenceId: occurrence.id,
      status: status,
      snoozeCount: occurrence.snoozeCount,
      responseTime: occurrence.responseTime,
    );
  }

  /// Mapeia uma lista de ocorrências, descartando as não-terminadas
  /// e as CANCELLED. Ordem de entrada é preservada.
  List<OccurrenceOutcome> toOutcomes(List<TaskOccurrence> occurrences) {
    return occurrences.map(toOutcome).whereType<OccurrenceOutcome>().toList();
  }

  OutcomeStatus? _mapStatus(OccurrenceStatus status) {
    switch (status) {
      case OccurrenceStatus.completed:
        return OutcomeStatus.completed;
      case OccurrenceStatus.missed:
        return OutcomeStatus.missed;
      case OccurrenceStatus.declined:
        return OutcomeStatus.declined;
      case OccurrenceStatus.scheduled:
      case OccurrenceStatus.triggered:
      case OccurrenceStatus.snoozed:
      case OccurrenceStatus.cancelled:
        return null;
    }
  }

  /// Constrói a lista de DayOutcome (input do StreakEngine) para
  /// cada dia entre [rangeStart] e [rangeEnd] (inclusive), a partir
  /// de todas as TaskOccurrence agendadas nesse intervalo.
  ///
  /// [today] evita que o dia corrente seja marcado como "broken"
  /// prematuramente enquanto ainda tiver ocorrências por resolver.
  List<DayOutcome> toDayOutcomes({
    required List<TaskOccurrence> occurrences,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime today,
  }) {
    final byDay = <DateTime, List<TaskOccurrence>>{};
    for (final occurrence in occurrences) {
      final day = _dateOnly(occurrence.scheduledAt);
      byDay.putIfAbsent(day, () => []).add(occurrence);
    }

    final todayKey = _dateOnly(today);
    final result = <DayOutcome>[];

    for (var day = _dateOnly(rangeStart);
        !day.isAfter(_dateOnly(rangeEnd));
        day = day.add(const Duration(days: 1))) {
      final dayOccurrences = byDay[day];

      if (dayOccurrences == null || dayOccurrences.isEmpty) {
        result.add(
          DayOutcome(date: day, fulfillment: DayFulfillment.neutral),
        );
        continue;
      }

      final isToday = day == todayKey;
      final hasUnresolved = dayOccurrences.any(
        (o) =>
            o.status == OccurrenceStatus.scheduled ||
            o.status == OccurrenceStatus.triggered ||
            o.status == OccurrenceStatus.snoozed,
      );

      if (isToday && hasUnresolved) {
        // Dia ainda em curso — não penaliza nem conta ainda.
        result.add(
          DayOutcome(date: day, fulfillment: DayFulfillment.neutral),
        );
        continue;
      }

      final relevant = dayOccurrences
          .where((o) => o.status != OccurrenceStatus.cancelled)
          .toList();

      if (relevant.isEmpty) {
        // Só havia CANCELLED nesse dia — não conta para nada.
        result.add(
          DayOutcome(date: day, fulfillment: DayFulfillment.neutral),
        );
        continue;
      }

      final allCompleted = relevant.every(
        (o) => o.status == OccurrenceStatus.completed,
      );

      result.add(
        DayOutcome(
          date: day,
          fulfillment:
              allCompleted ? DayFulfillment.fulfilled : DayFulfillment.broken,
        ),
      );
    }

    return result;
  }

  DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}
