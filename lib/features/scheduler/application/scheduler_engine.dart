import '../../../core/result/result.dart';
import '../../tasks/domain/alarm_scheduler.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/alarm_id_generator.dart';
import '../domain/alarm_notifier.dart';
import '../domain/alarm_record.dart';
import '../domain/alarm_repository.dart';

/// The Scheduler Engine (master spec §13): schedule, cancel,
/// reschedule, rescheduleAll (the basis for Fase 7's recovery).
///
/// Implements [AlarmScheduler] so `TaskEngine` can call it without
/// knowing anything about notifications, timezones, or Drift.
class SchedulerEngine implements AlarmScheduler {
  SchedulerEngine({
    required AlarmNotifier notificationService,
    required AlarmRepository alarmRepository,
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
  })  : _notifications = notificationService,
        _alarms = alarmRepository,
        _occurrences = occurrenceRepository,
        _tasks = taskRepository;

  final AlarmNotifier _notifications;
  final AlarmRepository _alarms;
  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;

  @override
  Future<Result<void>> scheduleOccurrence(TaskOccurrence occurrence) async {
    final Result<Task?> taskResult = await _tasks.getTask(occurrence.taskId);
    final Task? task = taskResult.valueOrNull;
    final String title = task?.title ?? 'GuiaGo';

    final int nativeId = AlarmIdGenerator.fromOccurrenceId(occurrence.id);
    final Result<void> scheduleResult = await _notifications.scheduleAt(
      id: nativeId,
      title: title,
      body: 'Está agendado para agora.',
      scheduledAt: occurrence.scheduledAt,
      payload: occurrence.id,
    );
    if (scheduleResult case Fail<void>(:final failure)) {
      return Fail<void>(failure);
    }

    final AlarmRecord record = AlarmRecord(
      occurrenceId: occurrence.id,
      taskId: occurrence.taskId,
      nativeAlarmId: nativeId,
      scheduledAt: occurrence.scheduledAt,
      createdAt: DateTime.now(),
    );
    final Result<AlarmRecord> saveResult =
        await _alarms.saveAlarmRecord(record);
    if (saveResult case Fail<AlarmRecord>(:final failure)) {
      return Fail<void>(failure);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancelOccurrence(String occurrenceId) async {
    final Result<AlarmRecord?> recordResult =
        await _alarms.getAlarmRecord(occurrenceId);
    final AlarmRecord? record = recordResult.valueOrNull;
    if (record == null) return const Success<void>(null);

    final Result<void> cancelResult =
        await _notifications.cancel(record.nativeAlarmId);
    if (cancelResult case Fail<void>(:final failure)) {
      return Fail<void>(failure);
    }
    return _alarms.deleteAlarmRecord(occurrenceId);
  }

  /// Cancels and re-schedules a single occurrence — used after a
  /// snooze changes its `scheduledAt`.
  Future<Result<void>> reschedule(TaskOccurrence occurrence) async {
    await cancelOccurrence(occurrence.id);
    return scheduleOccurrence(occurrence);
  }

  /// Re-schedules every currently-live occurrence. This is the
  /// engine-level "recovery" master spec §13 asks for — Fase 7 will
  /// call this on boot; for now it's also usable manually (e.g.
  /// right after the user grants notification permission).
  Future<Result<void>> rescheduleAll() async {
    final Result<List<TaskOccurrence>> occurrencesResult =
        await _occurrences.getAllActiveOccurrences();
    if (occurrencesResult case Fail<List<TaskOccurrence>>(:final failure)) {
      return Fail<void>(failure);
    }
    for (final TaskOccurrence occurrence in occurrencesResult.valueOrNull!) {
      await cancelOccurrence(occurrence.id);
      await scheduleOccurrence(occurrence);
    }
    return const Success<void>(null);
  }
}
