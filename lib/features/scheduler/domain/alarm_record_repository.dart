import '../../../core/result/result.dart';
import 'alarm_record.dart';

/// Domain-facing contract for reading/writing [AlarmRecord]s.
/// Implemented by `DriftAlarmRecordRepository` in the Data layer.
abstract interface class AlarmRecordRepository {
  Future<Result<AlarmRecord>> saveAlarmRecord(AlarmRecord record);

  /// The current live (`status == scheduled`) alarm for
  /// [occurrenceId], if any. An occurrence has at most one live
  /// alarm at a time — [SchedulerEngine] always cancels the previous
  /// one before scheduling a replacement.
  Future<Result<AlarmRecord?>> getActiveAlarmForOccurrence(
    String occurrenceId,
  );

  /// Every [AlarmRecord] currently `status == scheduled`, across all
  /// occurrences. Used by recovery/diagnostics (master spec §13,
  /// §26) and later by the Dashboard.
  Future<Result<List<AlarmRecord>>> getAllScheduledAlarmRecords();

  /// Whether [nativeAlarmId] is already used by a live
  /// (`status == scheduled`) alarm — checked before handing the id
  /// to the OS scheduler, so two occurrences never collide on the
  /// same native notification id.
  Future<Result<bool>> nativeAlarmIdInUse(int nativeAlarmId);
}
