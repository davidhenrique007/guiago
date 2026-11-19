import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/recovery/application/recovery_service.dart';
import 'package:guiago/features/recovery/domain/recovery_report.dart';
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

/// Records what the platform would have been asked to do.
class _FakeNotifier implements AlarmNotifier {
  final List<({int id, DateTime scheduledAt, String payload})> scheduled =
      <({int id, DateTime scheduledAt, String payload})>[];
  bool failScheduling = false;

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (failScheduling) return const Fail<void>(AlarmFailure('boom'));
    scheduled.add((id: id, scheduledAt: scheduledAt, payload: payload));
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancel(int id) async => const Success<void>(null);

  @override
  Future<Result<void>> cancelAll() async => const Success<void>(null);

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

Task _task(String id, RecurrenceRule rule) {
  final DateTime now = DateTime.now();
  return Task(
    id: id,
    title: 'Tarefa $id',
    priority: TaskPriority.medium,
    recurrenceRule: rule,
    defaultToleranceMinutes: 15,
    defaultSnoozeMinutes: 10,
    createdAt: now,
    updatedAt: now,
    isArchived: false,
  );
}

void main() {
  late AppDatabase db;
  late DriftTaskOccurrenceRepository occurrences;
  late _FakeNotifier notifier;
  late RecoveryService service;
  late DateTime now;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime.now();

    final DriftTaskRepository tasks = DriftTaskRepository(db);
    occurrences = DriftTaskOccurrenceRepository(db);
    notifier = _FakeNotifier();
    final SchedulerEngine scheduler = SchedulerEngine(
      notificationService: notifier,
      alarmRepository: DriftAlarmRepository(db),
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
    final TaskEngine engine = TaskEngine(
      taskRepository: tasks,
      occurrenceRepository: occurrences,
      eventRepository: DriftTaskEventRepository(db),
      alarmScheduler: scheduler,
    );
    service = RecoveryService(
      occurrenceRepository: occurrences,
      taskEngine: engine,
      scheduler: scheduler,
      clock: () => now,
    );

    await tasks.saveTask(_task('t1', const RecurrenceRule.none()));
    await tasks.saveTask(_task('t2', const RecurrenceRule.daily()));
  });

  tearDown(() => db.close());

  Future<void> seed(
    String id,
    DateTime scheduledAt, {
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    DateTime? triggeredAt,
    String taskId = 't1',
  }) {
    return occurrences.saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: taskId,
        scheduledAt: scheduledAt,
        triggeredAt: triggeredAt,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<OccurrenceStatus?> statusOf(String id) async {
    return (await occurrences.getOccurrence(id)).valueOrNull?.status;
  }

  group('RecoveryService.run', () {
    test('re-arms the alarm of a future occurrence', () async {
      await seed('o1', now.add(const Duration(hours: 1)));

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.rescheduled, 1);
      expect(report.markedMissed, 0);
      expect(notifier.scheduled, hasLength(1));
      expect(notifier.scheduled.single.payload, 'o1');
      expect(notifier.scheduled.single.scheduledAt.isAfter(now), isTrue);
    });

    test('surfaces an overdue occurrence that is still inside its tolerance',
        () async {
      await seed('o1', now.subtract(const Duration(minutes: 5)));

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.surfaced, 1);
      expect(notifier.scheduled.single.payload, 'o1');
      expect(notifier.scheduled.single.scheduledAt.isAfter(now), isTrue);
      expect(await statusOf('o1'), OccurrenceStatus.scheduled);
    });

    test('marks a scheduled occurrence past its tolerance as missed', () async {
      await seed('o1', now.subtract(const Duration(hours: 2)));

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.markedMissed, 1);
      expect(report.changedOccurrences, isTrue);
      expect(await statusOf('o1'), OccurrenceStatus.missed);
    });

    test('marks a triggered occurrence past its tolerance as missed', () async {
      await seed(
        'o1',
        now.subtract(const Duration(hours: 2)),
        status: OccurrenceStatus.triggered,
        triggeredAt: now.subtract(const Duration(hours: 1)),
      );

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.markedMissed, 1);
      expect(await statusOf('o1'), OccurrenceStatus.missed);
    });

    test('surfaces a triggered occurrence that is still inside its tolerance',
        () async {
      await seed(
        'o1',
        now.subtract(const Duration(minutes: 10)),
        status: OccurrenceStatus.triggered,
        triggeredAt: now.subtract(const Duration(minutes: 5)),
      );

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.surfaced, 1);
      expect(report.markedMissed, 0);
      expect(await statusOf('o1'), OccurrenceStatus.triggered);
    });

    test('catches up a daily task whose phone was off for days', () async {
      await seed(
        'r0',
        now.subtract(const Duration(hours: 70)),
        taskId: 't2',
      );

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.markedMissed, 3);
      expect(await statusOf('r0'), OccurrenceStatus.missed);

      final List<TaskOccurrence> active =
          (await occurrences.getAllActiveOccurrences()).valueOrNull!;
      expect(active, hasLength(1));
      expect(active.single.scheduledAt.isAfter(now), isTrue);
      expect(report.rescheduled, 1);
    });

    test('leaves alone the occurrence that is being opened right now',
        () async {
      await seed('o1', now.subtract(const Duration(hours: 2)));

      final RecoveryReport report =
          (await service.run(excludeOccurrenceId: 'o1')).valueOrNull!;

      expect(report.markedMissed, 0);
      expect(await statusOf('o1'), OccurrenceStatus.scheduled);
    });

    test('a scheduling failure is reported and does not abort the run',
        () async {
      await seed('o1', now.add(const Duration(hours: 1)));
      notifier.failScheduling = true;

      final Result<RecoveryReport> result = await service.run();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.rescheduled, 0);
      expect(result.valueOrNull!.failures, hasLength(1));
      expect(result.valueOrNull!.hasFailures, isTrue);
    });

    test('does nothing when there are no live occurrences', () async {
      await seed(
        'o1',
        now.subtract(const Duration(days: 1)),
        status: OccurrenceStatus.completed,
      );

      final RecoveryReport report = (await service.run()).valueOrNull!;

      expect(report.rescheduled, 0);
      expect(report.surfaced, 0);
      expect(report.markedMissed, 0);
      expect(notifier.scheduled, isEmpty);
    });

    test(
        'a second run started while one is in progress returns an empty '
        'report', () async {
      await seed('o1', now.add(const Duration(hours: 1)));

      final Future<Result<RecoveryReport>> first = service.run();
      final Result<RecoveryReport> second = await service.run();
      final Result<RecoveryReport> firstResult = await first;

      expect(second.valueOrNull!.rescheduled, 0);
      expect(firstResult.valueOrNull!.rescheduled, 1);
    });
  });
}
