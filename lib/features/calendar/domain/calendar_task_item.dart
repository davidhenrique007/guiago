import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task_priority.dart';

part 'calendar_task_item.freezed.dart';

/// One occurrence on a calendar day, already joined with its Task's
/// title and priority — the Calendar screen never looks up a Task
/// itself (master spec §5).
@freezed
sealed class CalendarTaskItem with _$CalendarTaskItem {
  const factory CalendarTaskItem({
    required String occurrenceId,
    required String taskId,
    required String title,
    required TaskPriority priority,
    required DateTime scheduledAt,
    required OccurrenceStatus status,
  }) = _CalendarTaskItem;
}
