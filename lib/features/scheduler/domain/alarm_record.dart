import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_record.freezed.dart';

/// Links a [TaskOccurrence] to the native alarm/notification that
/// was scheduled for it (master spec §13: "Cada alarme deve possuir
/// relação com TaskOccurrence + AlarmRecord").
///
/// Keyed by `occurrenceId` — an occurrence has at most one live
/// [AlarmRecord] at a time, so there is no separate `id` field.
@freezed
sealed class AlarmRecord with _$AlarmRecord {
  const factory AlarmRecord({
    required String occurrenceId,
    required String taskId,
    required int nativeAlarmId,
    required DateTime scheduledAt,
    required DateTime createdAt,
  }) = _AlarmRecord;

  const AlarmRecord._();
}
