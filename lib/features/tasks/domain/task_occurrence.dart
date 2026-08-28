import 'package:freezed_annotation/freezed_annotation.dart';

import 'occurrence_status.dart';

part 'task_occurrence.freezed.dart';

/// A single scheduled instance of a [Task] (master spec §10).
///
/// Its `status` only ever changes through [OccurrenceStateMachine] —
/// never assigned directly.
@freezed
sealed class TaskOccurrence with _$TaskOccurrence {
  const factory TaskOccurrence({
    required String id,
    required String taskId,
    required DateTime scheduledAt,
    DateTime? triggeredAt,
    DateTime? completedAt,
    required OccurrenceStatus status,
    required int snoozeCount,
    Duration? responseTime,
    required int toleranceMinutes,
    String? declineReason,
  }) = _TaskOccurrence;

  const TaskOccurrence._();
}
