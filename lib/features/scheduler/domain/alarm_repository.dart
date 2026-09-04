import '../../../core/result/result.dart';
import 'alarm_record.dart';

/// Domain-facing contract for reading/writing [AlarmRecord]s.
/// Implemented by `DriftAlarmRepository` in the Data layer.
abstract interface class AlarmRepository {
  Future<Result<AlarmRecord>> saveAlarmRecord(AlarmRecord record);

  Future<Result<AlarmRecord?>> getAlarmRecord(String occurrenceId);

  Future<Result<void>> deleteAlarmRecord(String occurrenceId);

  /// All currently-live alarm records — the foundation for
  /// `SchedulerEngine.rescheduleAll()` (§13's "recovery"), which
  /// Fase 7 will call on boot.
  Future<Result<List<AlarmRecord>>> getAllAlarmRecords();
}
