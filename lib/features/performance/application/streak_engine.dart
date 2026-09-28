// GuiaGo — Fase 5: Performance Engine + Gamification
// StreakEngine (secção 21 da master spec)

import '../domain/day_outcome.dart';
import '../domain/streak_status.dart';

class StreakEngine {
  const StreakEngine();

  /// [days] deve estar em ordem cronológica ascendente (mais
  /// antigo primeiro, hoje por último) e idealmente sem buracos
  /// de datas — um dia sem ocorrências ainda deve aparecer como
  /// [DayFulfillment.neutral], não estar ausente da lista.
  StreakStatus calculate({
    required List<DayOutcome> days,
    required DateTime calculatedAt,
  }) {
    var running = 0;
    var longest = 0;
    DateTime? lastFulfilled;

    for (final day in days) {
      switch (day.fulfillment) {
        case DayFulfillment.fulfilled:
          running += 1;
          lastFulfilled = day.date;
        case DayFulfillment.neutral:
          break; // não quebra nem estende
        case DayFulfillment.broken:
          running = 0;
      }
      if (running > longest) longest = running;
    }

    return StreakStatus(
      currentStreak: running,
      longestStreak: longest,
      lastFulfilledDate: lastFulfilled,
      calculatedAt: calculatedAt,
    );
  }
}
