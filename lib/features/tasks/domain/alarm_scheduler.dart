import '../../../core/result/result.dart';
import 'task_occurrence.dart';

/// Domain-facing contract the Task Engine uses to keep native alarms
/// in sync with occurrence lifecycle changes (master spec §13).
///
/// Defined here (in `tasks/domain`, the consumer) rather than in
/// `features/scheduler`, so `TaskEngine` never has to import the
/// scheduler feature — only `SchedulerEngine` (in
/// `features/scheduler/application`) imports this interface, to
/// implement it. That keeps the dependency one-directional:
/// scheduler → tasks, never tasks → scheduler.
abstract interface class AlarmScheduler {
  Future<Result<void>> scheduleOccurrence(TaskOccurrence occurrence);

  Future<Result<void>> cancelOccurrence(String occurrenceId);
}
