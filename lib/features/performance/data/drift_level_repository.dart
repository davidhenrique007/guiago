// GuiaGo — Fase 5: Performance Engine + Gamification
// Implementação Drift de LevelRepository (histórico multi-linha).

import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/level.dart';
import '../domain/level_repository.dart';

class DriftLevelRepository implements LevelRepository {
  DriftLevelRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<LevelStatus>> saveEvaluation(LevelStatus status) async {
    try {
      await _db.into(_db.levelsTable).insertOnConflictUpdate(
            LevelsTableCompanion.insert(
              id: status.id,
              tier: status.tier.name,
              previousTier: status.previousTier.name,
              scoreAtEvaluation: status.scoreAtEvaluation,
              evaluatedAt: status.evaluatedAt,
            ),
          );
      return Success<LevelStatus>(status);
    } catch (e) {
      return Fail<LevelStatus>(
        DatabaseFailure('Failed to save level evaluation', cause: e),
      );
    }
  }

  @override
  Future<Result<LevelStatus?>> getLatest() async {
    try {
      final LevelRow? row = await (_db.select(_db.levelsTable)
            ..orderBy([(l) => OrderingTerm.desc(l.evaluatedAt)])
            ..limit(1))
          .getSingleOrNull();
      return Success<LevelStatus?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<LevelStatus?>(
        DatabaseFailure('Failed to load latest level', cause: e),
      );
    }
  }

  @override
  Future<Result<List<LevelStatus>>> getHistory() async {
    try {
      final List<LevelRow> rows = await (_db.select(_db.levelsTable)
            ..orderBy([(l) => OrderingTerm.asc(l.evaluatedAt)]))
          .get();
      return Success<List<LevelStatus>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<LevelStatus>>(
        DatabaseFailure('Failed to load level history', cause: e),
      );
    }
  }

  LevelStatus _toDomain(LevelRow row) => LevelStatus(
        id: row.id,
        tier: LevelTier.values.byName(row.tier),
        previousTier: LevelTier.values.byName(row.previousTier),
        scoreAtEvaluation: row.scoreAtEvaluation,
        evaluatedAt: row.evaluatedAt,
      );
}
