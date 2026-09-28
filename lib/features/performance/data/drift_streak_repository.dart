// GuiaGo — Fase 5: Performance Engine + Gamification
// Implementação Drift de StreakRepository.
//
// StreakStatus é single-row (id fixo = 0, mesmo padrão do
// SettingsTable e do ScoresTable).

import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/streak_repository.dart';
import '../domain/streak_status.dart';

class DriftStreakRepository implements StreakRepository {
  DriftStreakRepository(this._db);

  final AppDatabase _db;

  static const int _singletonId = 0;

  @override
  Future<Result<void>> saveStatus(StreakStatus status) async {
    try {
      await _db.into(_db.streakStatusTable).insertOnConflictUpdate(
            StreakStatusTableCompanion.insert(
              id: const Value<int>(_singletonId),
              currentStreak: Value<int>(status.currentStreak),
              longestStreak: Value<int>(status.longestStreak),
              lastFulfilledDate: Value<DateTime?>(status.lastFulfilledDate),
              calculatedAt: status.calculatedAt,
            ),
          );
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        DatabaseFailure('Failed to save streak status', cause: e),
      );
    }
  }

  @override
  Future<Result<StreakStatus?>> getStatus() async {
    try {
      final StreakStatusRow? row = await (_db.select(_db.streakStatusTable)
            ..where((s) => s.id.equals(_singletonId)))
          .getSingleOrNull();
      return Success<StreakStatus?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<StreakStatus?>(
        DatabaseFailure('Failed to load streak status', cause: e),
      );
    }
  }

  StreakStatus _toDomain(StreakStatusRow row) => StreakStatus(
        currentStreak: row.currentStreak,
        longestStreak: row.longestStreak,
        lastFulfilledDate: row.lastFulfilledDate,
        calculatedAt: row.calculatedAt,
      );
}
