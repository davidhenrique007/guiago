import '../../../core/result/result.dart';
import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/calendar_day_snapshot.dart';
import '../domain/calendar_task_item.dart';

/// Read-only assembler of a [CalendarDaySnapshot] — same shape as
/// `HomeService`. Shows only occurrences that are already persisted:
/// recurrences are generated one at a time (master spec §12), so
/// future days are never projected here.
class CalendarService {
  CalendarService({
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
  })  : _occurrences = occurrenceRepository,
        _tasks = taskRepository;

  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;

  Future<Result<CalendarDaySnapshot>> load(DateTime day) async {
    final DateTime dayStart = DateTime(day.year, day.month, day.day);
    // Calendar arithmetic, not Duration, so DST changes cannot shift
    // the boundary (same rule as HomeService).
    final DateTime dayEnd = DateTime(day.year, day.month, day.day + 1)
        .subtract(const Duration(microseconds: 1));

    final Result<List<TaskOccurrence>> occurrencesResult =
        await _occurrences.getOccurrencesInRange(dayStart, dayEnd);
    if (occurrencesResult.isFailure) {
      return Fail<CalendarDaySnapshot>(occurrencesResult.failureOrNull!);
    }

    final List<TaskOccurrence> occurrences = <TaskOccurrence>[
      ...occurrencesResult.valueOrNull!,
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final List<CalendarTaskItem> items = <CalendarTaskItem>[];
    for (final TaskOccurrence occurrence in occurrences) {
      if (occurrence.status == OccurrenceStatus.cancelled) continue;

      final Result<Task?> taskResult = await _tasks.getTask(occurrence.taskId);
      if (taskResult.isFailure) {
        return Fail<CalendarDaySnapshot>(taskResult.failureOrNull!);
      }
      final Task? task = taskResult.valueOrNull;
      if (task == null) continue; // task deleted after being scheduled

      items.add(
        CalendarTaskItem(
          occurrenceId: occurrence.id,
          taskId: task.id,
          title: task.title,
          priority: task.priority,
          scheduledAt: occurrence.scheduledAt,
          status: occurrence.status,
        ),
      );
    }

    return Success<CalendarDaySnapshot>(
      CalendarDaySnapshot(day: dayStart, items: items),
    );
  }
}
