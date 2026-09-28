// GuiaGo — Fase 5: Performance Engine + Gamification
// Interface de repositório do StreakStatus (agregado single-row).

import '../../../core/result/result.dart';
import 'streak_status.dart';

abstract interface class StreakRepository {
  Future<Result<void>> saveStatus(StreakStatus status);

  /// null se o streak ainda não tiver sido calculado nenhuma vez.
  Future<Result<StreakStatus?>> getStatus();
}
