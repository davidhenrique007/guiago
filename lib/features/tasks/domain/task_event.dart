import 'package:freezed_annotation/freezed_annotation.dart';

import 'occurrence_status.dart';

part 'task_event.freezed.dart';

/// An append-only log entry recording one [TaskOccurrence] status
/// transition (master spec §10 — "the system must preserve
/// history"). Never updated or deleted, only ever inserted by
/// [TaskEngine] alongside the occurrence update that caused it.
@freezed
sealed class TaskEvent with _$TaskEvent {
  const factory TaskEvent({
    required String id,
    required String taskId,
    required String occurrenceId,
    required OccurrenceStatus fromStatus,
    required OccurrenceStatus toStatus,
    required DateTime occurredAt,
    String? note,
  }) = _TaskEvent;

  const TaskEvent._();
}
