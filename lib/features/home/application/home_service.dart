import '../../../core/result/result.dart';
import '../../onboarding/domain/settings_repository.dart';
import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/home_snapshot.dart';
import '../domain/today_task_item.dart';

/// Read-only assembler of a [HomeSnapshot] — same shape as
/// DashboardService (Fase 6B): never writes, only reads and joins
/// what other features already persisted.
class HomeService {
  HomeService({
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
    required SettingsRepository settingsRepository,
  })  : _occurrences = occurrenceRepository,
        _tasks = taskRepository,
        _settings = settingsRepository;

  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;
  final SettingsRepository _settings;

  /// [now] exists only so tests can pin the clock.
  Future<Result<HomeSnapshot>> load({DateTime? now}) async {
    final DateTime clock = now ?? DateTime.now();
    final DateTime dayStart = DateTime(clock.year, clock.month, clock.day);
    final DateTime dayEnd = DateTime(clock.year, clock.month, clock.day + 1)
        .subtract(const Duration(microseconds: 1));

    final settingsResult = await _settings.getSettings();
    if (settingsResult.isFailure) {
      return Fail<HomeSnapshot>(settingsResult.failureOrNull!);
    }

    final occurrencesResult = await _occurrences.getOccurrencesInRange(
      dayStart,
      dayEnd,
    );
    if (occurrencesResult.isFailure) {
      return Fail<HomeSnapshot>(occurrencesResult.failureOrNull!);
    }

    final List<TaskOccurrence> occurrences = occurrencesResult.valueOrNull!
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final List<TodayTaskItem> items = <TodayTaskItem>[];
    for (final TaskOccurrence occurrence in occurrences) {
      // Cancelled occurrences (task deleted/archived) don't belong on
      // the Home list — same rule as the Fase 5 mapper.
      if (occurrence.status == OccurrenceStatus.cancelled) continue;

      final taskResult = await _tasks.getTask(occurrence.taskId);
      if (taskResult.isFailure) {
        return Fail<HomeSnapshot>(taskResult.failureOrNull!);
      }
      final Task? task = taskResult.valueOrNull;
      if (task == null) continue; // task deleted after being scheduled

      items.add(
        TodayTaskItem(
          occurrenceId: occurrence.id,
          taskId: task.id,
          title: task.title,
          priority: task.priority,
          scheduledAt: occurrence.scheduledAt,
          status: occurrence.status,
        ),
      );
    }

    TodayTaskItem? next;
    for (final TodayTaskItem item in items) {
      if (!item.isResolved) {
        next = item;
        break;
      }
    }

    return Success<HomeSnapshot>(
      HomeSnapshot(
        userName: settingsResult.valueOrNull!.userName,
        today: dayStart,
        todayTasks: items,
        nextTask: next,
      ),
    );
  }
}
