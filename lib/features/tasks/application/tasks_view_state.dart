import '../domain/occurrence_status.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';

/// One occurrence in the Tasks tab, already joined with its task's
/// title and priority — the screen never looks a task up itself.
class TaskListItem {
  const TaskListItem({
    required this.occurrenceId,
    required this.taskId,
    required this.title,
    required this.priority,
    required this.scheduledAt,
    required this.status,
    this.resolvedAt,
  });

  final String occurrenceId;
  final String taskId;
  final String title;
  final TaskPriority priority;
  final DateTime scheduledAt;
  final OccurrenceStatus status;

  /// When a resolved occurrence was completed (null while pending or
  /// when it was declined/missed).
  final DateTime? resolvedAt;
}

/// The three lists of the Tasks tab.
///
/// * [today]: pending occurrences scheduled up to the end of today
///   (overdue ones that are still pending included);
/// * [upcoming]: pending occurrences after today;
/// * [completed]: resolved occurrences (completed, declined, missed),
///   most recent first.
class TasksSnapshot {
  const TasksSnapshot({
    required this.today,
    required this.upcoming,
    required this.completed,
  });

  static const TasksSnapshot empty = TasksSnapshot(
    today: <TaskListItem>[],
    upcoming: <TaskListItem>[],
    completed: <TaskListItem>[],
  );

  final List<TaskListItem> today;
  final List<TaskListItem> upcoming;
  final List<TaskListItem> completed;

  bool get isEmpty => today.isEmpty && upcoming.isEmpty && completed.isEmpty;
}

/// What the edit form needs: the task and, when it still has a
/// pending occurrence, the time that can be changed.
class TaskEditDraft {
  const TaskEditDraft({required this.task, this.scheduledAt});

  final Task task;

  /// Null when the task has no pending (scheduled/snoozed) occurrence.
  final DateTime? scheduledAt;
}
