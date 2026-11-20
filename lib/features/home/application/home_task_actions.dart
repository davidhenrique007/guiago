import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../tasks/application/task_engine.dart';
import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';

/// The two quick actions of the Home: "Concluir" and "Adiar".
///
/// A pending occurrence is `scheduled`, and the state machine only
/// allows `triggered -> completed/snoozed`. So, when the user acts on
/// it from the Home (without the alarm having rung), the occurrence is
/// first moved to `triggered` through [TaskEngine] and then resolved —
/// the state machine is never bypassed.
class HomeTaskActions {
  HomeTaskActions({
    required TaskEngine taskEngine,
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
    DateTime Function()? clock,
  })  : _engine = taskEngine,
        _occurrences = occurrenceRepository,
        _tasks = taskRepository,
        _clock = clock ?? DateTime.now;

  final TaskEngine _engine;
  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;
  final DateTime Function() _clock;

  Future<Result<void>> complete(String occurrenceId) async {
    final Result<TaskOccurrence> ready = await _ensureTriggered(occurrenceId);
    if (ready case Fail<TaskOccurrence>(:final failure)) {
      return Fail<void>(failure);
    }
    final Result<TaskOccurrence> result =
        await _engine.completeOccurrence(occurrenceId);
    return _asVoid(result);
  }

  /// Snoozes by the task's own `defaultSnoozeMinutes`. Only allowed
  /// once the occurrence is due: snoozing a future occurrence would
  /// move it EARLIER (the engine pushes it to now + minutes).
  Future<Result<void>> snooze(String occurrenceId) async {
    final Result<TaskOccurrence?> fetched =
        await _occurrences.getOccurrence(occurrenceId);
    if (fetched case Fail<TaskOccurrence?>(:final failure)) {
      return Fail<void>(failure);
    }
    final TaskOccurrence? occurrence = fetched.valueOrNull;
    if (occurrence == null) {
      return Fail<void>(
        ValidationFailure('Occurrence $occurrenceId not found'),
      );
    }
    if (occurrence.scheduledAt.isAfter(_clock())) {
      return const Fail<void>(
        ValidationFailure('Ainda não é a hora de adiar esta tarefa.'),
      );
    }

    final Result<Task?> taskResult = await _tasks.getTask(occurrence.taskId);
    final int minutes = taskResult.valueOrNull?.defaultSnoozeMinutes ?? 10;

    final Result<TaskOccurrence> ready = await _ensureTriggered(occurrenceId);
    if (ready case Fail<TaskOccurrence>(:final failure)) {
      return Fail<void>(failure);
    }
    final Result<TaskOccurrence> result = await _engine.snoozeOccurrence(
      occurrenceId,
      snoozeMinutes: minutes,
    );
    return _asVoid(result);
  }

  Future<Result<TaskOccurrence>> _ensureTriggered(String occurrenceId) async {
    final Result<TaskOccurrence?> fetched =
        await _occurrences.getOccurrence(occurrenceId);
    if (fetched case Fail<TaskOccurrence?>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    final TaskOccurrence? occurrence = fetched.valueOrNull;
    if (occurrence == null) {
      return Fail<TaskOccurrence>(
        ValidationFailure('Occurrence $occurrenceId not found'),
      );
    }
    if (occurrence.status == OccurrenceStatus.scheduled) {
      return _engine.triggerOccurrence(occurrenceId);
    }
    if (occurrence.status == OccurrenceStatus.triggered) {
      return Success<TaskOccurrence>(occurrence);
    }
    return const Fail<TaskOccurrence>(
      ValidationFailure('Esta tarefa já foi resolvida.'),
    );
  }

  Result<void> _asVoid(Result<TaskOccurrence> result) => switch (result) {
        Success<TaskOccurrence>() => const Success<void>(null),
        Fail<TaskOccurrence>(:final failure) => Fail<void>(failure),
      };
}
