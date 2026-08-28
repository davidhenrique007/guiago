import '../../../core/result/result.dart';
import 'task_event.dart';

/// Domain-facing contract for the append-only [TaskEvent] history
/// log. Implemented by `DriftTaskEventRepository` in the Data layer.
abstract interface class TaskEventRepository {
  Future<Result<void>> recordEvent(TaskEvent event);

  /// History for one occurrence, oldest first.
  Future<Result<List<TaskEvent>>> getEventsForOccurrence(String occurrenceId);
}
