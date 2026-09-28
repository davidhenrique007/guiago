// GuiaGo — Fase 5: Performance Engine + Gamification
// Implementação Drift de PerformanceRecordRepository.

import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/performance_record.dart';
import '../domain/performance_record_repository.dart';

class DriftPerformanceRecordRepository implements PerformanceRecordRepository {
  DriftPerformanceRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<PerformanceRecord>> saveRecord(
    PerformanceRecord record,
  ) async {
    try {
      await _db.into(_db.performanceRecordsTable).insertOnConflictUpdate(
            PerformanceRecordsTableCompanion.insert(
              id: record.id,
              periodStart: record.periodStart,
              periodEnd: record.periodEnd,
              totalOccurrences: record.totalOccurrences,
              completedCount: record.completedCount,
              completedAfterSnoozeCount: record.completedAfterSnoozeCount,
              missedCount: record.missedCount,
              declinedCount: record.declinedCount,
              snoozedCount: record.snoozedCount,
              completionRate: record.completionRate,
              missRate: record.missRate,
              snoozeRate: record.snoozeRate,
              averageResponseTimeSeconds:
                  Value<int?>(record.averageResponseTime?.inSeconds),
              calculatedAt: record.calculatedAt,
            ),
          );
      return Success<PerformanceRecord>(record);
    } catch (e) {
      return Fail<PerformanceRecord>(
        DatabaseFailure('Failed to save performance record', cause: e),
      );
    }
  }

  @override
  Future<Result<List<PerformanceRecord>>> getRecordsInRange(
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    try {
      final List<PerformanceRecordRow> rows =
          await (_db.select(_db.performanceRecordsTable)
                ..where(
                  (r) =>
                      r.periodStart.isBiggerOrEqualValue(periodStart) &
                      r.periodEnd.isSmallerOrEqualValue(periodEnd),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.periodStart)]))
              .get();
      return Success<List<PerformanceRecord>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<PerformanceRecord>>(
        DatabaseFailure('Failed to load performance records', cause: e),
      );
    }
  }

  PerformanceRecord _toDomain(PerformanceRecordRow row) => PerformanceRecord(
        id: row.id,
        periodStart: row.periodStart,
        periodEnd: row.periodEnd,
        totalOccurrences: row.totalOccurrences,
        completedCount: row.completedCount,
        completedAfterSnoozeCount: row.completedAfterSnoozeCount,
        missedCount: row.missedCount,
        declinedCount: row.declinedCount,
        snoozedCount: row.snoozedCount,
        completionRate: row.completionRate,
        missRate: row.missRate,
        snoozeRate: row.snoozeRate,
        averageResponseTime: row.averageResponseTimeSeconds == null
            ? null
            : Duration(seconds: row.averageResponseTimeSeconds!),
        calculatedAt: row.calculatedAt,
      );
}
