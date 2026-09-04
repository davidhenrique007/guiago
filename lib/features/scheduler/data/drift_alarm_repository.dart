import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/alarm_record.dart';
import '../domain/alarm_repository.dart';

class DriftAlarmRepository implements AlarmRepository {
  DriftAlarmRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<AlarmRecord>> saveAlarmRecord(AlarmRecord record) async {
    try {
      await _db.into(_db.alarmRecordsTable).insertOnConflictUpdate(
            AlarmRecordsTableCompanion.insert(
              occurrenceId: record.occurrenceId,
              taskId: record.taskId,
              nativeAlarmId: record.nativeAlarmId,
              scheduledAt: record.scheduledAt,
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
  Future<Result<AlarmRecord?>> getAlarmRecord(String occurrenceId) async {
    try {
      final AlarmRecordRow? row = await (_db.select(_db.alarmRecordsTable)
            ..where((a) => a.occurrenceId.equals(occurrenceId)))
          .getSingleOrNull();
      return Success<AlarmRecord?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<AlarmRecord?>(
        DatabaseFailure('Failed to load alarm record', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> deleteAlarmRecord(String occurrenceId) async {
    try {
      await (_db.delete(_db.alarmRecordsTable)
            ..where((a) => a.occurrenceId.equals(occurrenceId)))
          .go();
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        DatabaseFailure('Failed to delete alarm record', cause: e),
      );
    }
  }

  @override
  Future<Result<List<AlarmRecord>>> getAllAlarmRecords() async {
    try {
      final List<AlarmRecordRow> rows =
          await _db.select(_db.alarmRecordsTable).get();
      return Success<List<AlarmRecord>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<AlarmRecord>>(
        DatabaseFailure('Failed to load alarm records', cause: e),
      );
    }
  }

  AlarmRecord _toDomain(AlarmRecordRow row) => AlarmRecord(
        occurrenceId: row.occurrenceId,
        taskId: row.taskId,
        nativeAlarmId: row.nativeAlarmId,
        scheduledAt: row.scheduledAt,
        createdAt: row.createdAt,
      );
}
