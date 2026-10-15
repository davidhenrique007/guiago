import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task_priority.dart';

part 'today_task_item.freezed.dart';

/// One of today's occurrences, already joined with its Task's title
/// and priority — the Home screen never looks up a Task itself
/// (master spec §5: UI doesn't touch repositories directly).
@freezed
sealed class TodayTaskItem with _$TodayTaskItem {
  const factory TodayTaskItem({
    required String occurrenceId,
    required String taskId,
    required String title,
    required TaskPriority priority,
    required DateTime scheduledAt,
    required OccurrenceStatus status,
  }) = _TodayTaskItem;

  const TodayTaskItem._();

  bool get isResolved =>
      status == OccurrenceStatus.completed ||
      status == OccurrenceStatus.declined ||
      status == OccurrenceStatus.missed ||
      status == OccurrenceStatus.cancelled;
}
