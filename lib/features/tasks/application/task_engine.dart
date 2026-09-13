import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/alarm_scheduler.dart';
import '../domain/occurrence_state_machine.dart';
import '../domain/occurrence_status.dart';
import '../domain/recurrence_engine.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_event.dart';
import '../domain/task_event_repository.dart';
import '../domain/task_occurrence.dart';
import '../domain/task_occurrence_repository.dart';
import '../domain/task_priority.dart';
import '../domain/task_repository.dart';

/// The Task Engine (master spec §17). This is the ONLY place allowed
/// to change an occurrence's status — always through
/// [OccurrenceStateMachine] — and the only place that decides when
/// the Recurrence Engine should generate the next occurrence.
///
/// [alarmScheduler] is optional: when null (as in every Fase 2 test),
/// the engine works exactly as it did before Fase 3 — no scheduling
/// side effects. When provided, occurrence creation/resolution/snooze
/// also keeps native alarms in sync — best-effort, never blocking the
/// underlying operation on a scheduling failure (see ADR-006).
class TaskEngine {
  TaskEngine({
    required TaskRepository taskRepository,
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskEventRepository eventRepository,
    AlarmScheduler? alarmScheduler,
    Uuid? uuid,
  })  : _tasks = taskRepository,
        _occurrences = occurrenceRepository,
        _events = eventRepository,
        _alarmScheduler = alarmScheduler,
        _uuid = uuid ?? const Uuid();

  final TaskRepository _tasks;
  final TaskOccurrenceRepository _occurrences;
  final TaskEventRepository _events;
  final AlarmScheduler? _alarmScheduler;
  final Uuid _uuid;

  /// Creates a task and its first occurrence at [scheduledAt].
  /// Further occurrences are generated one at a time as each prior
  /// one resolves (§12) — never generated up front.
  Future<Result<Task>> createTask({
    required String title,
    String? description,
    required TaskPriority priority,
    required RecurrenceRule recurrenceRule,
    required DateTime scheduledAt,
    int? toleranceMinutes,
    int? snoozeMinutes,
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return const Fail<Task>(ValidationFailure('Task title is required'));
    }

    final DateTime now = DateTime.now();
    final Task task = Task(
      id: _uuid.v4(),
      title: trimmedTitle,
      description: description,
      priority: priority,
      recurrenceRule: recurrenceRule,
      defaultToleranceMinutes: toleranceMinutes ?? 15,
      defaultSnoozeMinutes: snoozeMinutes ?? 10,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
    );

    final Result<Task> saveResult = await _tasks.saveTask(task);
    if (saveResult case Fail<Task>(:final failure)) {
      return Fail<Task>(failure);
    }

    final TaskOccurrence occurrence = TaskOccurrence(
      id: _uuid.v4(),
      taskId: task.id,
      scheduledAt: scheduledAt,
      status: OccurrenceStatus.scheduled,
      snoozeCount: 0,
      toleranceMinutes: task.defaultToleranceMinutes,
    );
    final Result<TaskOccurrence> occurrenceResult =
        await _occurrences.saveOccurrence(occurrence);
    if (occurrenceResult case Fail<TaskOccurrence>(:final failure)) {
      return Fail<Task>(failure);
    }

    await _alarmScheduler?.scheduleOccurrence(occurrence);

    return Success<Task>(task);
  }

  Future<Result<Task>> updateTask(Task task) {
    final Task updated = task.copyWith(updatedAt: DateTime.now());
    return _tasks.saveTask(updated);
  }

  Future<Result<void>> archiveTask(String taskId) => _tasks.archiveTask(taskId);

  Future<Result<void>> deleteTask(String taskId) => _tasks.deleteTask(taskId);

  /// Marks the occurrence triggered — the alarm has fired and the
  /// user is looking at it. Called by `AlarmRingController` when the
  /// alarm screen opens (Fase 4).
  Future<Result<TaskOccurrence>> triggerOccurrence(String occurrenceId) async {
    final Result<TaskOccurrence?> fetchResult =
        await _occurrences.getOccurrence(occurrenceId);
    if (fetchResult case Fail<TaskOccurrence?>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    final TaskOccurrence? current = fetchResult.valueOrNull;
    if (current == null) {
      return Fail<TaskOccurrence>(
        ValidationFailure('Occurrence $occurrenceId not found'),
      );
    }

    final Result<OccurrenceStatus> transition =
        OccurrenceStateMachine.transition(
      current.status,
      OccurrenceStatus.triggered,
    );
    if (transition case Fail<OccurrenceStatus>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }

    final TaskOccurrence triggered = current.copyWith(
      status: OccurrenceStatus.triggered,
      triggeredAt: DateTime.now(),
    );
    final Result<TaskOccurrence> saveResult =
        await _occurrences.saveOccurrence(triggered);
    if (saveResult case Fail<TaskOccurrence>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }

    await _recordEvent(current, OccurrenceStatus.triggered);

    return Success<TaskOccurrence>(triggered);
  }

  /// Marks the occurrence completed and, if the task recurs,
  /// generates and schedules the next occurrence.
  Future<Result<TaskOccurrence>> completeOccurrence(
    String occurrenceId, {
    Duration? responseTime,
  }) {
    return _resolveOccurrence(
      occurrenceId,
      OccurrenceStatus.completed,
      applyExtras: (TaskOccurrence occ) => occ.copyWith(
        completedAt: DateTime.now(),
        responseTime: responseTime,
      ),
    );
  }

  /// Marks the occurrence declined (optionally with a reason) and,
  /// if the task recurs, generates and schedules the next occurrence.
  Future<Result<TaskOccurrence>> declineOccurrence(
    String occurrenceId, {
    String? reason,
  }) {
    return _resolveOccurrence(
      occurrenceId,
      OccurrenceStatus.declined,
      applyExtras: (TaskOccurrence occ) => occ.copyWith(declineReason: reason),
    );
  }

  /// Marks the occurrence missed and, if the task recurs, generates
  /// and schedules the next occurrence.
  Future<Result<TaskOccurrence>> markMissed(String occurrenceId) {
    return _resolveOccurrence(occurrenceId, OccurrenceStatus.missed);
  }

  /// Snoozes the occurrence: increments `snoozeCount`, pushes
  /// `scheduledAt` forward by [snoozeMinutes], and re-arms the alarm
  /// for the new time. Per §11, SNOOZED must return to SCHEDULED — it
  /// never resolves the occurrence, so no next occurrence is
  /// generated here.
  Future<Result<TaskOccurrence>> snoozeOccurrence(
    String occurrenceId, {
    int snoozeMinutes = 10,
  }) async {
    final Result<TaskOccurrence?> fetchResult =
        await _occurrences.getOccurrence(occurrenceId);
    if (fetchResult case Fail<TaskOccurrence?>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    final TaskOccurrence? current = fetchResult.valueOrNull;
    if (current == null) {
      return Fail<TaskOccurrence>(
        ValidationFailure('Occurrence $occurrenceId not found'),
      );
    }

    final Result<OccurrenceStatus> snoozedTransition =
        OccurrenceStateMachine.transition(
      current.status,
      OccurrenceStatus.snoozed,
    );
    if (snoozedTransition case Fail<OccurrenceStatus>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    await _recordEvent(current, OccurrenceStatus.snoozed);

    final Result<OccurrenceStatus> rescheduleTransition =
        OccurrenceStateMachine.transition(
      OccurrenceStatus.snoozed,
      OccurrenceStatus.scheduled,
    );
    if (rescheduleTransition case Fail<OccurrenceStatus>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }

    final TaskOccurrence rescheduled = current.copyWith(
      status: OccurrenceStatus.scheduled,
      snoozeCount: current.snoozeCount + 1,
      scheduledAt: DateTime.now().add(Duration(minutes: snoozeMinutes)),
    );
    final Result<TaskOccurrence> saveResult =
        await _occurrences.saveOccurrence(rescheduled);
    if (saveResult case Fail<TaskOccurrence>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    await _recordEvent(
      current.copyWith(status: OccurrenceStatus.snoozed),
      OccurrenceStatus.scheduled,
    );

    await _alarmScheduler?.cancelOccurrence(occurrenceId);
    await _alarmScheduler?.scheduleOccurrence(rescheduled);

    return Success<TaskOccurrence>(rescheduled);
  }

  /// Shared implementation for the three terminal transitions
  /// (completed/declined/missed): validate via the state machine,
  /// persist, log the [TaskEvent], cancel the resolved occurrence's
  /// alarm, then generate + schedule the task's next occurrence if
  /// it recurs.
  Future<Result<TaskOccurrence>> _resolveOccurrence(
    String occurrenceId,
    OccurrenceStatus toStatus, {
    TaskOccurrence Function(TaskOccurrence occurrence)? applyExtras,
  }) async {
    final Result<TaskOccurrence?> fetchResult =
        await _occurrences.getOccurrence(occurrenceId);
    if (fetchResult case Fail<TaskOccurrence?>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }
    final TaskOccurrence? current = fetchResult.valueOrNull;
    if (current == null) {
      return Fail<TaskOccurrence>(
        ValidationFailure('Occurrence $occurrenceId not found'),
      );
    }

    final Result<OccurrenceStatus> transition =
        OccurrenceStateMachine.transition(current.status, toStatus);
    if (transition case Fail<OccurrenceStatus>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }

    TaskOccurrence resolved = current.copyWith(status: toStatus);
    if (applyExtras != null) {
      resolved = applyExtras(resolved);
    }

    final Result<TaskOccurrence> saveResult =
        await _occurrences.saveOccurrence(resolved);
    if (saveResult case Fail<TaskOccurrence>(:final failure)) {
      return Fail<TaskOccurrence>(failure);
    }

    await _recordEvent(current, toStatus);
    await _alarmScheduler?.cancelOccurrence(occurrenceId);

    final TaskOccurrence? next =
        await _generateNextOccurrenceIfRecurring(resolved);
    if (next != null) {
      await _alarmScheduler?.scheduleOccurrence(next);
    }

    return Success<TaskOccurrence>(resolved);
  }

  Future<TaskOccurrence?> _generateNextOccurrenceIfRecurring(
    TaskOccurrence resolvedOccurrence,
  ) async {
    final Result<Task?> taskResult =
        await _tasks.getTask(resolvedOccurrence.taskId);
    final Task? task = taskResult.valueOrNull;
    if (task == null || task.isArchived) return null;

    final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
      recurrenceRule: task.recurrenceRule,
      anchor: resolvedOccurrence.scheduledAt,
      after: resolvedOccurrence.scheduledAt,
    );
    if (next == null) return null;

    final TaskOccurrence nextOccurrence = TaskOccurrence(
      id: _uuid.v4(),
      taskId: task.id,
      scheduledAt: next,
      status: OccurrenceStatus.scheduled,
      snoozeCount: 0,
      toleranceMinutes: task.defaultToleranceMinutes,
    );
    final Result<TaskOccurrence> saveResult =
        await _occurrences.saveOccurrence(nextOccurrence);
    return saveResult.valueOrNull;
  }

  Future<void> _recordEvent(
    TaskOccurrence before,
    OccurrenceStatus toStatus,
  ) {
    return _events.recordEvent(
      TaskEvent(
        id: _uuid.v4(),
        taskId: before.taskId,
        occurrenceId: before.id,
        fromStatus: before.status,
        toStatus: toStatus,
        occurredAt: DateTime.now(),
      ),
    );
  }
}
