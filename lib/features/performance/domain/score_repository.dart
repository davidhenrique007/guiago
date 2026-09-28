// GuiaGo — Fase 5: Performance Engine + Gamification
// Interface de repositório do Score (agregado + ledger).

import '../../../core/result/result.dart';
import 'score.dart';

abstract interface class ScoreRepository {
  /// Devolve o agregado atual. Se ainda não houver nenhum score
  /// persistido, devolve Score(total: 0) — nunca null.
  Future<Result<Score>> getScore();

  Future<Result<void>> saveScore(Score score);

  /// Insere uma entry no ledger (append-only, nunca update).
  Future<Result<ScoreEntry>> saveEntry(ScoreEntry entry);

  /// Todo o ledger, em ordem cronológica ascendente. Usado para
  /// recomputar o agregado quando necessário.
  Future<Result<List<ScoreEntry>>> getEntries();
}
