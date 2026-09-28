// GuiaGo — Fase 5: Performance Engine + Gamification
// Implementação Drift de ScoreRepository.
//
// Scores é single-row (id fixo = 0, mesmo padrão do SettingsTable).
// ScoreEntries é o ledger append-only.

import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/score.dart';
import '../domain/score_repository.dart';

class DriftScoreRepository implements ScoreRepository {
  DriftScoreRepository(this._db);

  final AppDatabase _db;

  static const int _singletonId = 0;

  @override
  Future<Result<Score>> getScore() async {
    try {
      final ScoreRow? row = await (_db.select(_db.scoresTable)
            ..where((s) => s.id.equals(_singletonId)))
          .getSingleOrNull();
      if (row == null) {
        return Success<Score>(Score(total: 0, updatedAt: DateTime.now()));
      }
      return Success<Score>(_toDomain(row));
    } catch (e) {
      return Fail<Score>(DatabaseFailure('Failed to load score', cause: e));
    }
  }

  @override
  Future<Result<void>> saveScore(Score score) async {
    try {
      await _db.into(_db.scoresTable).insertOnConflictUpdate(
            ScoresTableCompanion.insert(
              id: const Value<int>(_singletonId),
              total: Value<int>(score.total),
              updatedAt: score.updatedAt,
            ),
          );
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(DatabaseFailure('Failed to save score', cause: e));
    }
  }

  @override
  Future<Result<ScoreEntry>> saveEntry(ScoreEntry entry) async {
    try {
      await _db.into(_db.scoreEntriesTable).insertOnConflictUpdate(
            ScoreEntriesTableCompanion.insert(
              id: entry.id,
              occurrenceId: entry.occurrenceId,
              reason: entry.reason.name,
              points: entry.points,
              occurredAt: entry.occurredAt,
            ),
          );
      return Success<ScoreEntry>(entry);
    } catch (e) {
      return Fail<ScoreEntry>(
        DatabaseFailure('Failed to save score entry', cause: e),
      );
    }
  }

  @override
  Future<Result<List<ScoreEntry>>> getEntries() async {
    try {
      final List<ScoreEntryRow> rows = await (_db.select(
        _db.scoreEntriesTable,
      )..orderBy([(e) => OrderingTerm.asc(e.occurredAt)]))
          .get();
      return Success<List<ScoreEntry>>(rows.map(_toEntryDomain).toList());
    } catch (e) {
      return Fail<List<ScoreEntry>>(
        DatabaseFailure('Failed to load score entries', cause: e),
      );
    }
  }

  Score _toDomain(ScoreRow row) => Score(
        total: row.total,
        updatedAt: row.updatedAt,
      );

  ScoreEntry _toEntryDomain(ScoreEntryRow row) => ScoreEntry(
        id: row.id,
        occurrenceId: row.occurrenceId,
        reason: ScoringReason.values.byName(row.reason),
        points: row.points,
        occurredAt: row.occurredAt,
      );
}
