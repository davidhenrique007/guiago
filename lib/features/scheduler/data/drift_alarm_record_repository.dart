import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/alarm_record.dart';
import '../domain/alarm_record_repository.dart';
import '../domain/alarm_status.dart';

class DriftAlarmRecordRepository implements AlarmRecordRepository {
  DriftAlarmRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<AlarmRecord>> saveAlarmRecord(AlarmRecord record) async {
    try {
      await _db.into(_db.alarmRecordsTable).insertOnConflictUpdate(
            AlarmRecordsTableCompanion.insert(
              id: record.id,
              occurrenceId: record.occurrenceId,
              taskId: record.taskId,
              nativeAlarmId: record.nativeAlarmId,
              scheduledAt: record.scheduledAt,
              status: record.status.name,
              createdAt: record.createdAt,
            ),
          );
      return Success<AlarmRecord>(record);
    } catch (e) {
      return Fail<AlarmRecord>(
        DatabaseFailure('Failed to save alarm record', cause: e),
      );
    }
  }

  @override
  Future<Result<AlarmRecord?>> getActiveAlarmForOccurrence(
    String occurrenceId,
  ) async {
    try {
      final AlarmRecordRow? row = await (_db.select(_db.alarmRecordsTable)
            ..where(
              (a) =>
                  a.occurrenceId.equals(occurrenceId) &
                  a.status.equals(AlarmStatus.scheduled.name),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      return Success<AlarmRecord?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<AlarmRecord?>(
        DatabaseFailure('Failed to load active alarm record', cause: e),
      );
    }
  }

  @override
  Future<Result<List<AlarmRecord>>> getAllScheduledAlarmRecords() async {
    try {
      final List<AlarmRecordRow> rows = await (_db.select(
        _db.alarmRecordsTable,
      )..where((a) => a.status.equals(AlarmStatus.scheduled.name)))
          .get();
      return Success<List<AlarmRecord>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<AlarmRecord>>(
        DatabaseFailure('Failed to load scheduled alarm records', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> nativeAlarmIdInUse(int nativeAlarmId) async {
    try {
      final AlarmRecordRow? row = await (_db.select(_db.alarmRecordsTable)
            ..where(
              (a) =>
                  a.nativeAlarmId.equals(nativeAlarmId) &
                  a.status.equals(AlarmStatus.scheduled.name),
            )
            ..limit(1))
          .getSingleOrNull();
      return Success<bool>(row != null);
    } catch (e) {
      return Fail<bool>(
        DatabaseFailure('Failed to check native alarm id', cause: e),
      );
    }
  }

  AlarmRecord _toDomain(AlarmRecordRow row) => AlarmRecord(
        id: row.id,
        occurrenceId: row.occurrenceId,
        taskId: row.taskId,
        nativeAlarmId: row.nativeAlarmId,
        scheduledAt: row.scheduledAt,
        status: AlarmStatus.values.byName(row.status),
        createdAt: row.createdAt,
      );
}
