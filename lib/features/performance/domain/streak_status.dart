// GuiaGo — Fase 5: Performance Engine + Gamification
// Entidade de domínio: StreakStatus (secção 21 da master spec)
//
// Sem userId: app é single-user local.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_status.freezed.dart';

@freezed
sealed class StreakStatus with _$StreakStatus {
  const factory StreakStatus({
    required int currentStreak,
    required int longestStreak,
    DateTime? lastFulfilledDate,
    required DateTime calculatedAt,
  }) = _StreakStatus;
}
