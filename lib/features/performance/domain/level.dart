// GuiaGo — Fase 5: Performance Engine + Gamification
// Entidades de domínio: LevelTier, LevelStatus
//
// Ver secção 20 da master spec: o nível não depende apenas do
// score histórico — o LevelEngine deve considerar desempenho
// recente. Esta entidade é só o resultado dessa avaliação, não
// a lógica em si.
//
// Sem userId: app é single-user local. Tem `id` (ao contrário de
// Score/StreakStatus) porque é histórico multi-linha, não um
// agregado singleton — cada avaliação gera uma linha própria.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'level.freezed.dart';

enum LevelTier {
  beginner,
  consistent,
  disciplined,
  elite,
}

extension LevelTierOrder on LevelTier {
  /// Posição ordinal, útil para comparar/detectar subida ou descida.
  int get rank => LevelTier.values.indexOf(this);

  bool isAbove(LevelTier other) => rank > other.rank;
  bool isBelow(LevelTier other) => rank < other.rank;
}

@freezed
sealed class LevelStatus with _$LevelStatus {
  const factory LevelStatus({
    required String id,
    required LevelTier tier,
    required LevelTier previousTier,
    required int scoreAtEvaluation,
    required DateTime evaluatedAt,
  }) = _LevelStatus;
}
