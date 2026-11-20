import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/occurrence_status.dart';
import '../domain/task.dart';
import '../domain/task_occurrence.dart';
import '../domain/task_occurrence_repository.dart';
import '../domain/task_repository.dart';
import 'tasks_view_state.dart';

/// Read-only assembler of the Tasks tab (same shape as `HomeService`
/// and `CalendarService`). It only reads through the repository
/// interfaces; every change goes through `TaskEngine`.
class TasksService {
  TasksService({
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
    this.completedLimit = 50,
  })  : _occurrences = occurrenceRepository,
        _tasks = taskRepository;

  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;

  /// How many resolved occurrences the "Concluídas" list keeps.
  final int completedLimit;

  Future<Result<TasksSnapshot>> load({DateTime? now}) async {
    final DateTime reference = now ?? DateTime.now();
    // Calendar arithmetic, not Duration, so DST cannot shift the day
    // boundary (same rule as HomeService / CalendarService).
    final DateTime endOfToday = DateTime(
      reference.year,
      reference.month,
      reference.day + 1,
    );

    final Result<List<Task>> tasksResult = await _tasks.getActiveTasks();
    if (tasksResult case Fail<List<Task>>(:final failure)) {
      return Fail<TasksSnapshot>(failure);
    }

    final List<TaskListItem> today = <TaskListItem>[];
    final List<TaskListItem> upcoming = <TaskListItem>[];
    final List<TaskListItem> completed = <TaskListItem>[];

    for (final Task task in tasksResult.valueOrNull!) {
      final Result<List<TaskOccurrence>> occurrencesResult =
          await _occurrences.getOccurrencesForTask(task.id);
      if (occurrencesResult case Fail<List<TaskOccurrence>>(:final failure)) {
        return Fail<TasksSnapshot>(failure);
      }

      for (final TaskOccurrence occurrence in occurrencesResult.valueOrNull!) {
        final TaskListItem item = TaskListItem(
          occurrenceId: occurrence.id,
          taskId: task.id,
          title: task.title,
          priority: task.priority,
          scheduledAt: occurrence.scheduledAt,
          status: occurrence.status,
          resolvedAt: occurrence.completedAt,
        );
        switch (occurrence.status) {
          case OccurrenceStatus.scheduled:
          case OccurrenceStatus.triggered:
          case OccurrenceStatus.snoozed:
            if (occurrence.scheduledAt.isBefore(endOfToday)) {
              today.add(item);
            } else {
              upcoming.add(item);
            }
          case OccurrenceStatus.completed:
          case OccurrenceStatus.declined:
          case OccurrenceStatus.missed:
            completed.add(item);
          case OccurrenceStatus.cancelled:
            break;
        }
      }
    }

    int byTime(TaskListItem a, TaskListItem b) =>
        a.scheduledAt.compareTo(b.scheduledAt);
    today.sort(byTime);
    upcoming.sort(byTime);
    completed.sort(
      (TaskListItem a, TaskListItem b) => (b.resolvedAt ?? b.scheduledAt)
          .compareTo(a.resolvedAt ?? a.scheduledAt),
    );

    return Success<TasksSnapshot>(
      TasksSnapshot(
        today: today,
        upcoming: upcoming,
        completed: completed.take(completedLimit).toList(),
      ),
    );
  }

  /// Loads a task for the edit form. Archived or missing tasks fail.
  Future<Result<TaskEditDraft>> loadForEdit(String taskId) async {
    final Result<Task?> taskResult = await _tasks.getTask(taskId);
    if (taskResult case Fail<Task?>(:final failure)) {
      return Fail<TaskEditDraft>(failure);
    }
    final Task? task = taskResult.valueOrNull;
    if (task == null || task.isArchived) {
      return Fail<TaskEditDraft>(ValidationFailure('Task $taskId not found'));
    }

    final Result<TaskOccurrence?> liveResult =
        await _occurrences.getActiveOccurrenceForTask(taskId);
    final TaskOccurrence? live = liveResult.valueOrNull;
    final DateTime? editableAt = (live != null &&
            (live.status == OccurrenceStatus.scheduled ||
                live.status == OccurrenceStatus.snoozed))
        ? live.scheduledAt
        : null;

    return Success<TaskEditDraft>(
      TaskEditDraft(task: task, scheduledAt: editableAt),
    );
  }
}
