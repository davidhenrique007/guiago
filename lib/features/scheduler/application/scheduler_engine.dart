import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/alarm_record.dart';
import '../domain/alarm_record_repository.dart';
import '../domain/alarm_scheduler.dart';
import '../domain/alarm_status.dart';
import '../domain/permission_service.dart';

/// The Scheduler Engine (master spec §13): schedule, cancel,
/// reschedule, snooze, rescheduleAll, recovery. This is the ONLY
/// place allowed to call [AlarmScheduler] — [TaskEngine] never
/// touches native notifications directly, it only calls this engine.
///
/// Depends on `tasks/domain` (read-only: [Task], [TaskOccurrence] and
/// their repository interfaces) but never on `tasks/application` or
/// `tasks/data` — keeping the dependency one-directional
/// (`tasks/application` → `scheduler/application`, not the reverse).
class SchedulerEngine {
  SchedulerEngine({
    required AlarmRecordRepository alarmRepository,
    required TaskOccurrenceRepository occurrenceRepository,
    required TaskRepository taskRepository,
    required AlarmScheduler alarmScheduler,
    required PermissionService permissionService,
    Uuid? uuid,
  })  : _alarms = alarmRepository,
        _occurrences = occurrenceRepository,
        _tasks = taskRepository,
        _scheduler = alarmScheduler,
        _permissions = permissionService,
        _uuid = uuid ?? const Uuid();

  final AlarmRecordRepository _alarms;
  final TaskOccurrenceRepository _occurrences;
  final TaskRepository _tasks;
  final AlarmScheduler _scheduler;
  final PermissionService _permissions;
  final Uuid _uuid;

  /// Schedules the native alarm for [occurrence]. Cancels any
  /// existing live alarm for the same occurrence first, so this
  /// doubles as "reschedule" — safe to call again after a snooze or
  /// an edit to `scheduledAt`.
  Future<Result<AlarmRecord>> scheduleForOccurrence(
    TaskOccurrence occurrence,
  ) async {
    final Result<bool> notificationPermission =
        await _permissions.ensureNotificationPermission();
    if (notificationPermission case Fail<bool>(:final failure)) {
      return Fail<AlarmRecord>(failure);
    }
    if (notificationPermission.valueOrNull != true) {
      return const Fail<AlarmRecord>(
        PermissionFailure('Notification permission was not granted'),
      );
    }
    // Exact-alarm permission is Android 12+-only and best-effort: if
    // denied, the OS still delivers an inexact alarm rather than
    // none at all, so a denial here is not treated as fatal.
    await _permissions.ensureExactAlarmPermission();

    final Result<Task?> taskResult = await _tasks.getTask(occurrence.taskId);
    if (taskResult case Fail<Task?>(:final failure)) {
      return Fail<AlarmRecord>(failure);
    }
    final Task? task = taskResult.valueOrNull;
    if (task == null) {
      return Fail<AlarmRecord>(
        ValidationFailure('Task ${occurrence.taskId} not found'),
      );
    }

    final Result<void> cancelResult = await cancelForOccurrence(occurrence.id);
    if (cancelResult case Fail<void>(:final failure)) {
      return Fail<AlarmRecord>(failure);
    }

    final Result<int> idResult = await _reserveNativeAlarmId();
    if (idResult case Fail<int>(:final failure)) {
      return Fail<AlarmRecord>(failure);
    }
    final int nativeAlarmId = idResult.valueOrNull!;

    final String body =
        (task.description != null && task.description!.trim().isNotEmpty)
            ? task.description!
            : 'Está na hora.';

    final Result<void> nativeResult = await _scheduler.scheduleAlarm(
      nativeAlarmId: nativeAlarmId,
      scheduledAt: occurrence.scheduledAt,
      title: task.title,
      body: body,
      payload: occurrence.id,
    );
    if (nativeResult case Fail<void>(:final failure)) {
      return Fail<AlarmRecord>(failure);
    }

    final AlarmRecord record = AlarmRecord(
      id: _uuid.v4(),
      occurrenceId: occurrence.id,
      taskId: task.id,
      nativeAlarmId: nativeAlarmId,
      scheduledAt: occurrence.scheduledAt,
      status: AlarmStatus.scheduled,
      createdAt: DateTime.now(),
    );
    return _alarms.saveAlarmRecord(record);
  }

  /// Cancels the live native alarm for [occurrenceId], if any.
  /// Idempotent — succeeds even when nothing was scheduled.
  Future<Result<void>> cancelForOccurrence(String occurrenceId) async {
    final Result<AlarmRecord?> existingResult =
        await _alarms.getActiveAlarmForOccurrence(occurrenceId);
    if (existingResult case Fail<AlarmRecord?>(:final failure)) {
      return Fail<void>(failure);
    }
    final AlarmRecord? existing = existingResult.valueOrNull;
    if (existing == null) return const Success<void>(null);

    final Result<void> cancelResult =
        await _scheduler.cancelAlarm(existing.nativeAlarmId);
    if (cancelResult case Fail<void>(:final failure)) {
      return Fail<void>(failure);
    }

    final Result<AlarmRecord> saveResult = await _alarms.saveAlarmRecord(
      existing.copyWith(status: AlarmStatus.cancelled),
    );
    if (saveResult case Fail<AlarmRecord>(:final failure)) {
      return Fail<void>(failure);
    }
    return const Success<void>(null);
  }

  /// Recovery (master spec §13, prepares for Fase 7's Boot Recovery):
  /// re-schedules every active task's current live occurrence against
  /// the device's *current* timezone/clock. Best-effort — one
  /// occurrence failing to reschedule doesn't stop the rest. Returns
  /// the count successfully (re)scheduled.
  Future<Result<int>> rescheduleAll() async {
    final Result<List<Task>> tasksResult = await _tasks.getActiveTasks();
    if (tasksResult case Fail<List<Task>>(:final failure)) {
      return Fail<int>(failure);
    }

    int rescheduledCount = 0;
    for (final Task task in tasksResult.valueOrNull ?? const <Task>[]) {
      final Result<TaskOccurrence?> occurrenceResult =
          await _occurrences.getActiveOccurrenceForTask(task.id);
      final TaskOccurrence? occurrence = occurrenceResult.valueOrNull;
      if (occurrence == null) continue;

      final Result<AlarmRecord> result =
          await scheduleForOccurrence(occurrence);
      if (result.isSuccess) rescheduledCount++;
    }
    return Success<int>(rescheduledCount);
  }

  /// Generates a candidate native alarm id and retries with a fresh
  /// candidate if it collides with one already in use — see
  /// `AlarmRecordRepository.nativeAlarmIdInUse`.
  Future<Result<int>> _reserveNativeAlarmId() async {
    for (int attempt = 0; attempt < 10; attempt++) {
      final int candidate = _hashToPositiveInt('${_uuid.v4()}#$attempt');
      final Result<bool> inUseResult =
          await _alarms.nativeAlarmIdInUse(candidate);
      if (inUseResult case Fail<bool>(:final failure)) {
        return Fail<int>(failure);
      }
      if (inUseResult.valueOrNull == false) {
        return Success<int>(candidate);
      }
    }
    return const Fail<int>(
      SchedulingFailure('Could not reserve a unique native alarm id'),
    );
  }

  /// FNV-1a 32-bit hash, masked to a positive 31-bit int — the range
  /// `flutter_local_notifications` expects for a notification id.
  /// Not a security primitive; only needs to be well-distributed
  /// enough to make collisions rare (uniqueness is still verified
  /// against [AlarmRecordRepository] before use).
  static int _hashToPositiveInt(String input) {
    int hash = 0x811c9dc5;
    for (final int codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
