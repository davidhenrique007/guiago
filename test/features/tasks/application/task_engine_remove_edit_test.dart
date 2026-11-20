import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/tasks/application/task_engine.dart';
import 'package:guiago/features/tasks/data/drift_task_event_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/alarm_scheduler.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

class _FakeAlarmScheduler implements AlarmScheduler {
  final List<String> scheduled = <String>[];
  final List<DateTime> scheduledTimes = <DateTime>[];
  final List<String> cancelled = <String>[];

  @override
  Future<Result<void>> scheduleOccurrence(TaskOccurrence occurrence) async {
    scheduled.add(occurrence.id);
    scheduledTimes.add(occurrence.scheduledAt);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancelOccurrence(String occurrenceId) async {
    cancelled.add(occurrenceId);
    return const Success<void>(null);
  }
}

void main() {
  late AppDatabase db;
  late TaskEngine engine;
  late _FakeAlarmScheduler scheduler;
  late DriftTaskRepository taskRepository;
  late DriftTaskOccurrenceRepository occurrenceRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    taskRepository = DriftTaskRepository(db);
    occurrenceRepository = DriftTaskOccurrenceRepository(db);
    scheduler = _FakeAlarmScheduler();
    engine = TaskEngine(
      taskRepository: taskRepository,
      occurrenceRepository: occurrenceRepository,
      eventRepository: DriftTaskEventRepository(db),
      alarmScheduler: scheduler,
    );
  });

  tearDown(() => db.close());

  final DateTime when = DateTime(2030, 3, 4, 9, 0);

  Future<String> createTask({
    RecurrenceRule rule = const RecurrenceRule.none(),
    String title = 'Estudar',
  }) async {
    final Result<Task> result = await engine.createTask(
      title: title,
      description: 'nota',
      priority: TaskPriority.low,
      recurrenceRule: rule,
      scheduledAt: when,
    );
    return result.valueOrNull!.id;
  }

  Future<TaskOccurrence> liveOccurrence(String taskId) async =>
      (await occurrenceRepository.getActiveOccurrenceForTask(taskId))
          .valueOrNull!;

  group('TaskEngine.removeTask', () {
    test('archives the task, cancels the occurrence and its alarm', () async {
      final String taskId = await createTask();
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      scheduler.cancelled.clear();

      final Result<void> result = await engine.removeTask(taskId);

      expect(result.isSuccess, isTrue);
      expect(
        (await taskRepository.getTask(taskId)).valueOrNull!.isArchived,
        isTrue,
      );
      expect((await taskRepository.getActiveTasks()).valueOrNull, isEmpty);
      final TaskOccurrence after =
          (await occurrenceRepository.getOccurrence(occurrence.id))
              .valueOrNull!;
      expect(after.status, OccurrenceStatus.cancelled);
      expect(scheduler.cancelled, contains(occurrence.id));
      expect(
        (await occurrenceRepository.getActiveOccurrenceForTask(taskId))
            .valueOrNull,
        isNull,
      );
    });

    test('keeps resolved occurrences (history stays intact)', () async {
      final String taskId = await createTask();
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      await engine.triggerOccurrence(occurrence.id);
      await engine.completeOccurrence(occurrence.id);

      await engine.removeTask(taskId);

      final TaskOccurrence after =
          (await occurrenceRepository.getOccurrence(occurrence.id))
              .valueOrNull!;
      expect(after.status, OccurrenceStatus.completed);
    });

    test('leaves a triggered occurrence for the user to resolve', () async {
      final String taskId = await createTask();
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      await engine.triggerOccurrence(occurrence.id);

      await engine.removeTask(taskId);

      final TaskOccurrence after =
          (await occurrenceRepository.getOccurrence(occurrence.id))
              .valueOrNull!;
      expect(after.status, OccurrenceStatus.triggered);
      expect(scheduler.cancelled, contains(occurrence.id));
    });

    test('a removed recurring task generates no next occurrence', () async {
      final String taskId =
          await createTask(rule: const RecurrenceRule.daily());
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      await engine.triggerOccurrence(occurrence.id);
      await engine.removeTask(taskId);

      await engine.completeOccurrence(occurrence.id);

      final List<TaskOccurrence> all =
          (await occurrenceRepository.getOccurrencesForTask(taskId))
              .valueOrNull!;
      expect(all, hasLength(1));
      expect(all.single.status, OccurrenceStatus.completed);
    });

    test('fails for an unknown task', () async {
      final Result<void> result = await engine.removeTask('nope');
      expect(result.isFailure, isTrue);
    });
  });

  group('TaskEngine.editTask', () {
    test('updates the task data and clears an empty description', () async {
      final String taskId = await createTask();

      final Result<Task> result = await engine.editTask(
        taskId: taskId,
        title: '  Estudar Dart  ',
        description: '   ',
        priority: TaskPriority.high,
        recurrenceRule: const RecurrenceRule.daily(),
        toleranceMinutes: 20,
        snoozeMinutes: 5,
      );

      expect(result.isSuccess, isTrue);
      final Task saved = (await taskRepository.getTask(taskId)).valueOrNull!;
      expect(saved.title, 'Estudar Dart');
      expect(saved.description, isNull);
      expect(saved.priority, TaskPriority.high);
      expect(saved.recurrenceRule, const RecurrenceRule.daily());
      expect(saved.defaultToleranceMinutes, 20);
      expect(saved.defaultSnoozeMinutes, 5);
    });

    test('moves the live occurrence and re-arms its alarm', () async {
      final String taskId = await createTask();
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      scheduler.scheduled.clear();
      scheduler.scheduledTimes.clear();
      scheduler.cancelled.clear();
      final DateTime newTime = DateTime(2030, 3, 5, 18, 30);

      await engine.editTask(
        taskId: taskId,
        title: 'Estudar',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 30,
        snoozeMinutes: 10,
        scheduledAt: newTime,
      );

      final TaskOccurrence after = await liveOccurrence(taskId);
      expect(after.id, occurrence.id);
      expect(after.scheduledAt, newTime);
      expect(after.toleranceMinutes, 30);
      expect(scheduler.cancelled, <String>[occurrence.id]);
      expect(scheduler.scheduled, <String>[occurrence.id]);
      expect(scheduler.scheduledTimes, <DateTime>[newTime]);
    });

    test('keeps the time when scheduledAt is not given', () async {
      final String taskId = await createTask();

      await engine.editTask(
        taskId: taskId,
        title: 'Novo título',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 15,
        snoozeMinutes: 10,
      );

      expect((await liveOccurrence(taskId)).scheduledAt, when);
    });

    test('does not touch a triggered occurrence', () async {
      final String taskId = await createTask();
      final TaskOccurrence occurrence = await liveOccurrence(taskId);
      await engine.triggerOccurrence(occurrence.id);
      scheduler.scheduled.clear();
      scheduler.cancelled.clear();

      await engine.editTask(
        taskId: taskId,
        title: 'Outro',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 45,
        snoozeMinutes: 10,
        scheduledAt: DateTime(2031, 1, 1, 8, 0),
      );

      final TaskOccurrence after = await liveOccurrence(taskId);
      expect(after.status, OccurrenceStatus.triggered);
      expect(after.scheduledAt, when);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelled, isEmpty);
    });

    test('rejects a blank title, unknown and archived tasks', () async {
      final String taskId = await createTask();

      final Result<Task> blank = await engine.editTask(
        taskId: taskId,
        title: '  ',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 15,
        snoozeMinutes: 10,
      );
      expect(blank.isFailure, isTrue);

      final Result<Task> unknown = await engine.editTask(
        taskId: 'nope',
        title: 'x',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 15,
        snoozeMinutes: 10,
      );
      expect(unknown.isFailure, isTrue);

      await engine.removeTask(taskId);
      final Result<Task> archived = await engine.editTask(
        taskId: taskId,
        title: 'x',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        toleranceMinutes: 15,
        snoozeMinutes: 10,
      );
      expect(archived.isFailure, isTrue);
    });
  });
}
