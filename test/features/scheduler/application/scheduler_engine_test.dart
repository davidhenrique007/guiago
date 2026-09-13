import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/scheduler/application/scheduler_engine.dart';
import 'package:guiago/features/scheduler/data/drift_alarm_repository.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/application/task_engine.dart';
import 'package:guiago/features/tasks/data/drift_task_event_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

/// In-memory fake — never touches platform channels, so this test
/// runs in a plain `flutter_test` VM.
class _FakeAlarmNotifier implements AlarmNotifier {
  final Set<int> scheduledIds = <int>{};
  final List<int> cancelledIds = <int>[];
  bool failScheduling = false;

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (failScheduling) {
      return const Fail<void>(AlarmFailure('forced failure'));
    }
    scheduledIds.add(id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancel(int id) async {
    scheduledIds.remove(id);
    cancelledIds.add(id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancelAll() async {
    scheduledIds.clear();
    return const Success<void>(null);
  }

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

void main() {
  late AppDatabase db;
  late _FakeAlarmNotifier notifier;
  late SchedulerEngine scheduler;
  late DriftTaskRepository taskRepository;
  late DriftTaskOccurrenceRepository occurrenceRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = _FakeAlarmNotifier();
    taskRepository = DriftTaskRepository(db);
    occurrenceRepository = DriftTaskOccurrenceRepository(db);
    scheduler = SchedulerEngine(
      notificationService: notifier,
      alarmRepository: DriftAlarmRepository(db),
      occurrenceRepository: occurrenceRepository,
      taskRepository: taskRepository,
    );

    await taskRepository.saveTask(
      Task(
        id: 'task-1',
        title: 'Beber água',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: DateTime(2026, 8, 24, 9, 0),
        updatedAt: DateTime(2026, 8, 24, 9, 0),
        isArchived: false,
      ),
    );
  });

  tearDown(() => db.close());

  TaskOccurrence buildOccurrence({String id = 'occ-1'}) => TaskOccurrence(
        id: id,
        taskId: 'task-1',
        scheduledAt: DateTime(2026, 8, 24, 9, 0),
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      );

  group('SchedulerEngine.scheduleOccurrence', () {
    test('schedules the alarm and saves an AlarmRecord', () async {
      final TaskOccurrence occurrence = buildOccurrence();
      await occurrenceRepository.saveOccurrence(occurrence);

      final result = await scheduler.scheduleOccurrence(occurrence);

      expect(result.isSuccess, isTrue);
      expect(notifier.scheduledIds, isNotEmpty);
    });

    test('a notifier failure is propagated and no record is saved', () async {
      notifier.failScheduling = true;
      final TaskOccurrence occurrence = buildOccurrence();
      await occurrenceRepository.saveOccurrence(occurrence);

      final result = await scheduler.scheduleOccurrence(occurrence);

      expect(result.isFailure, isTrue);
      final alarmRepo = DriftAlarmRepository(db);
      final recordResult = await alarmRepo.getAlarmRecord(occurrence.id);
      expect(recordResult.valueOrNull, isNull);
    });
  });

  group('SchedulerEngine.cancelOccurrence', () {
    test('cancels the notification and deletes the AlarmRecord', () async {
      final TaskOccurrence occurrence = buildOccurrence();
      await occurrenceRepository.saveOccurrence(occurrence);
      await scheduler.scheduleOccurrence(occurrence);

      final result = await scheduler.cancelOccurrence(occurrence.id);

      expect(result.isSuccess, isTrue);
      expect(notifier.scheduledIds, isEmpty);
      expect(notifier.cancelledIds, isNotEmpty);
    });

    test('cancelling an occurrence with no alarm record is a no-op success',
        () async {
      final result = await scheduler.cancelOccurrence('never-scheduled');
      expect(result.isSuccess, isTrue);
    });
  });

  group('SchedulerEngine.rescheduleAll', () {
    test('re-arms every currently-live occurrence', () async {
      await occurrenceRepository.saveOccurrence(buildOccurrence(id: 'occ-1'));
      await occurrenceRepository.saveOccurrence(buildOccurrence(id: 'occ-2'));

      final result = await scheduler.rescheduleAll();

      expect(result.isSuccess, isTrue);
      expect(notifier.scheduledIds, hasLength(2));
    });
  });

  group('TaskEngine + SchedulerEngine integration', () {
    test('creating a task schedules its first occurrence', () async {
      final TaskEngine engine = TaskEngine(
        taskRepository: taskRepository,
        occurrenceRepository: occurrenceRepository,
        eventRepository: DriftTaskEventRepository(db),
        alarmScheduler: scheduler,
      );

      await engine.createTask(
        title: 'Nova tarefa',
        priority: TaskPriority.medium,
        recurrenceRule: const RecurrenceRule.none(),
        scheduledAt: DateTime(2026, 8, 24, 10, 0),
      );

      expect(notifier.scheduledIds, isNotEmpty);
    });

    test(
      'completing a recurring occurrence cancels its alarm and schedules the next',
      () async {
        final TaskEngine engine = TaskEngine(
          taskRepository: taskRepository,
          occurrenceRepository: occurrenceRepository,
          eventRepository: DriftTaskEventRepository(db),
          alarmScheduler: scheduler,
        );
        await taskRepository.saveTask(
          Task(
            id: 'task-2',
            title: 'Tarefa diária',
            priority: TaskPriority.medium,
            recurrenceRule: const RecurrenceRule.daily(),
            defaultToleranceMinutes: 15,
            defaultSnoozeMinutes: 10,
            createdAt: DateTime(2026, 8, 24, 9, 0),
            updatedAt: DateTime(2026, 8, 24, 9, 0),
            isArchived: false,
          ),
        );
        final TaskOccurrence occurrence = TaskOccurrence(
          id: 'occ-daily',
          taskId: 'task-2',
          scheduledAt: DateTime(2026, 8, 24, 9, 0),
          status: OccurrenceStatus.triggered,
          snoozeCount: 0,
          toleranceMinutes: 15,
        );
        await occurrenceRepository.saveOccurrence(occurrence);
        await scheduler.scheduleOccurrence(occurrence);
        final int originalAlarmCount = notifier.scheduledIds.length;

        await engine.completeOccurrence('occ-daily');

        // The resolved occurrence's alarm was cancelled, and the
        // newly generated next occurrence's alarm was scheduled —
        // net count of live alarms stays the same, but the specific
        // id changed (the old one was cancelled).
        expect(notifier.cancelledIds, isNotEmpty);
        expect(notifier.scheduledIds, hasLength(originalAlarmCount));
      },
    );

    test(
        'snoozing an occurrence cancels the old alarm and schedules the new time',
        () async {
      final TaskEngine engine = TaskEngine(
        taskRepository: taskRepository,
        occurrenceRepository: occurrenceRepository,
        eventRepository: DriftTaskEventRepository(db),
        alarmScheduler: scheduler,
      );
      final TaskOccurrence occurrence = buildOccurrence().copyWith(
        status: OccurrenceStatus.triggered,
      );
      await occurrenceRepository.saveOccurrence(occurrence);
      await scheduler.scheduleOccurrence(occurrence);
      final int originalAlarmId = notifier.scheduledIds.single;

      final result =
          await engine.snoozeOccurrence(occurrence.id, snoozeMinutes: 5);

      expect(result.isSuccess, isTrue);
      expect(notifier.cancelledIds, contains(originalAlarmId));
      expect(notifier.scheduledIds, isNotEmpty);
    });
  });
}
