import '../../../core/result/result.dart';
import 'task_occurrence.dart';

/// Domain-facing contract for reading/writing [TaskOccurrence]s.
/// Implemented by `DriftTaskOccurrenceRepository` in the Data layer.
abstract interface class TaskOccurrenceRepository {
  Future<Result<TaskOccurrence>> saveOccurrence(TaskOccurrence occurrence);

  Future<Result<TaskOccurrence?>> getOccurrence(String id);

  /// All occurrences for one task, most recently scheduled first.
  Future<Result<List<TaskOccurrence>>> getOccurrencesForTask(String taskId);

  /// The single non-terminal (scheduled/triggered/snoozed) occurrence
  /// for a task, if one exists — a task has at most one "live"
  /// occurrence at a time (master spec §12: one generated at a time).
  Future<Result<TaskOccurrence?>> getActiveOccurrenceForTask(String taskId);

  /// All currently-live occurrences, across every task — the
  /// foundation for `SchedulerEngine.rescheduleAll()` (Fase 3) and
  /// Fase 7's boot recovery.
  Future<Result<List<TaskOccurrence>>> getAllActiveOccurrences();
}
