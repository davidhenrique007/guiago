// GuiaGo — Fase 5: Performance Engine + Gamification
// Interface de repositório do Level (histórico de avaliações).

import '../../../core/result/result.dart';
import 'level.dart';

abstract interface class LevelRepository {
  /// Insere uma nova avaliação (histórico append-only).
  Future<Result<LevelStatus>> saveEvaluation(LevelStatus status);

  /// A avaliação mais recente, ou null se ainda não houver nenhuma.
  Future<Result<LevelStatus?>> getLatest();

  Future<Result<List<LevelStatus>>> getHistory();
}
