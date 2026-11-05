import '../../../core/result/result.dart';
import '../../dashboard/domain/dashboard_period.dart';
import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/insights_policy.dart';
import '../domain/insights_snapshot.dart';
import 'productivity_engine.dart';

/// Read-only assembler of an [InsightsSnapshot] for the last 30 days
/// (`DashboardPeriod.month`, the same rolling window as the dashboard).
/// Reads `TaskOccurrence`s directly because the dashboard's
/// `OccurrenceOutcome` carries no time of day.
class InsightsService {
  InsightsService({
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
    ProductivityEngine engine = const ProductivityEngine(),
    InsightsPolicy policy = InsightsPolicy.defaultPolicy,
  })  : _occurrences = occurrenceRepository,
        _tasks = taskRepository,
        _engine = engine,
        _policy = policy;

  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;
  final ProductivityEngine _engine;
  final InsightsPolicy _policy;

  /// [now] exists only so tests can pin the clock.
  Future<Result<InsightsSnapshot>> load({DateTime? now}) async {
    final DashboardRange range =
        DashboardPeriod.month.rangeAt(now ?? DateTime.now());

    final Result<List<TaskOccurrence>> result =
        await _occurrences.getOccurrencesInRange(range.start, range.end);
    if (result.isFailure) {
      return Fail<InsightsSnapshot>(result.failureOrNull!);
    }

    final List<TaskOccurrence> completed = result.valueOrNull!
        .where((o) => o.status == OccurrenceStatus.completed)
        .toList();

    final List<int> histogram = _engine.histogram(completed);

    final Map<String, int> countByTask = <String, int>{};
    for (final TaskOccurrence occurrence in completed) {
      countByTask.update(occurrence.taskId, (c) => c + 1, ifAbsent: () => 1);
    }

    final List<TopTaskItem> ranked = <TopTaskItem>[];
    for (final MapEntry<String, int> entry in countByTask.entries) {
      final Result<Task?> taskResult = await _tasks.getTask(entry.key);
      if (taskResult.isFailure) {
        return Fail<InsightsSnapshot>(taskResult.failureOrNull!);
      }
      final Task? task = taskResult.valueOrNull;
      if (task == null) continue; // deleted task: not listed
      ranked.add(
        TopTaskItem(
          taskId: task.id,
          title: task.title,
          completedCount: entry.value,
        ),
      );
    }
    ranked.sort((a, b) {
      final int byCount = b.completedCount.compareTo(a.completedCount);
      return byCount != 0 ? byCount : a.title.compareTo(b.title);
    });

    return Success<InsightsSnapshot>(
      InsightsSnapshot(
        completionsByHour: histogram,
        totalCompletions: completed.length,
        peak: _engine.peak(histogram),
        topTasks: ranked.take(_policy.topTasksCount).toList(),
      ),
    );
  }
}
