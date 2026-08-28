import 'package:freezed_annotation/freezed_annotation.dart';

import 'alarm_status.dart';

part 'alarm_record.freezed.dart';

/// The relationship between one [TaskOccurrence] and the native OS
/// alarm scheduled for it (master spec §10, §13).
///
/// Pure Domain type — no Flutter, no `flutter_local_notifications`,
/// no Drift. [nativeAlarmId] is the only thing infrastructure code
/// needs to cancel or look up the underlying OS notification.
@freezed
sealed class AlarmRecord with _$AlarmRecord {
  const factory AlarmRecord({
    required String id,
    required String occurrenceId,
    required String taskId,
    required int nativeAlarmId,
    required DateTime scheduledAt,
    required AlarmStatus status,
    required DateTime createdAt,
  }) = _AlarmRecord;

  const AlarmRecord._();
}
