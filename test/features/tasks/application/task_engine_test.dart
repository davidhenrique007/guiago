import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/scheduler/application/scheduler_engine.dart';
import 'package:guiago/features/tasks/application/task_engine.dart';
import 'package:guiago/features/tasks/data/drift_task_event_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulerEngine extends Mock implements SchedulerEngine {}

void main() {
  late AppDatabase db;
  late TaskEngine engine;
  late DriftTaskOccurrenceRepository occurrenceRepository;
  late DriftTaskEventRepository eventRepository;
  late MockSchedulerEngine schedulerEngine;

  setUpAll(() {
    registerFallbackValue(
      TaskOccurrence(
        id: 'fallback',
        taskId: 'fallback',
        scheduledAt: DateTime(2026, 1, 1),
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    occurrenceRepository = DriftTaskOccurrenceRepository(db);
    eventRepository = DriftTaskEventRepository(db);
    schedulerEngine = MockSchedulerEngine();

    when(
      () => schedulerEngine.scheduleForOccurrence(any()),
    ).thenAnswer(
      (_) async => const Success(null),
    );

    when(
      () => schedulerEngine.cancelForOccurrence(any()),
    ).thenAnswer(
      (_) async => const Success(null),
    );

    engine = TaskEngine(
      taskRepository: DriftTaskRepository(db),
      occurrenceRepository: occurrenceRepository,
      eventRepository: eventRepository,
      schedulerEngine: schedulerEngine,
    );
  });

  tearDown(() => db.close());

  /// Creates a task via the engine (its first occurrence is
  /// SCHEDULED) then moves that occurrence straight to TRIGGERED by
  /// writing to the repository directly. Fase 2 has no Scheduler
  /// yet (that's Fase 3) — this stands in for "the alarm fired" so
  /// complete/decline/snooze can be exercised against a state the
  /// state machine actually allows them from.
  Future<String> createTriggeredOccurrence({
    RecurrenceRule recurrenceRule = const RecurrenceRule.none(),
    DateTime? scheduledAt,
  }) async {
    final result = await engine.createTask(
      title: 'Tarefa de teste',
      priority: TaskPriority.medium,
      recurrenceRule: recurrenceRule,
      scheduledAt: scheduledAt ?? DateTime(2026, 8, 24, 9, 0),
    );

    final String taskId = result.valueOrNull!.id;

    final TaskOccurrence scheduled =
        (await occurrenceRepository.getActiveOccurrenceForTask(taskId))
            .valueOrNull!;

    await occurrenceRepository.saveOccurrence(
      scheduled.copyWith(
        status: OccurrenceStatus.triggered,
        triggeredAt: scheduled.scheduledAt,
      ),
    );

    return scheduled.id;
  }

  group('TaskEngine.createTask', () {
    test('rejects a blank title', () async {
      final result = await engine.createTask(
        title: '   ',
        priority: TaskPriority.medium,
        recurrenceRule: const RecurrenceRule.none(),
        scheduledAt: DateTime(2026, 8, 24, 9, 0),
      );

      expect(result.isFailure, isTrue);
    });

    test('creates the task and its first occurrence as SCHEDULED', () async {
      final DateTime scheduledAt = DateTime(2026, 8, 24, 9, 0);

      final result = await engine.createTask(
        title: 'Estudar Flutter',
        priority: TaskPriority.high,
        recurrenceRule: const RecurrenceRule.none(),
        scheduledAt: scheduledAt,
      );

      expect(result.isSuccess, isTrue);

      final String taskId = result.valueOrNull!.id;

      final occurrenceResult =
          await occurrenceRepository.getActiveOccurrenceForTask(taskId);

      expect(occurrenceResult.valueOrNull?.scheduledAt, scheduledAt);
      expect(
        occurrenceResult.valueOrNull?.status,
        OccurrenceStatus.scheduled,
      );
    });
  });

  group('TaskEngine occurrence resolution', () {
    test(
      'completeOccurrence transitions TRIGGERED -> COMPLETED and logs an event',
      () async {
        final String occurrenceId = await createTriggeredOccurrence();

        final result = await engine.completeOccurrence(occurrenceId);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.status, OccurrenceStatus.completed);
        expect(result.valueOrNull?.completedAt, isNotNull);

        final events =
            await eventRepository.getEventsForOccurrence(occurrenceId);

        expect(events.valueOrNull, hasLength(1));

        expect(
          events.valueOrNull!.first.fromStatus,
          OccurrenceStatus.triggered,
        );

        expect(
          events.valueOrNull!.first.toStatus,
          OccurrenceStatus.completed,
        );
      },
    );

    test('completing a recurring task generates the next occurrence', () async {
      final String occurrenceId = await createTriggeredOccurrence(
        recurrenceRule: const RecurrenceRule.daily(),
      );

      final TaskOccurrence resolved =
          (await occurrenceRepository.getOccurrence(occurrenceId)).valueOrNull!;

      await engine.completeOccurrence(occurrenceId);

      final newActive = await occurrenceRepository
          .getActiveOccurrenceForTask(resolved.taskId);

      expect(newActive.valueOrNull, isNotNull);
      expect(newActive.valueOrNull!.id, isNot(occurrenceId));

      expect(
        newActive.valueOrNull!.scheduledAt,
        resolved.scheduledAt.add(const Duration(days: 1)),
      );
    });

    test(
      'completing a non-recurring task generates no next occurrence',
      () async {
        final String occurrenceId = await createTriggeredOccurrence(
          recurrenceRule: const RecurrenceRule.none(),
        );

        final String taskId =
            (await occurrenceRepository.getOccurrence(occurrenceId))
                .valueOrNull!
                .taskId;

        await engine.completeOccurrence(occurrenceId);

        final active =
            await occurrenceRepository.getActiveOccurrenceForTask(taskId);

        expect(active.valueOrNull, isNull);
      },
    );

    test('declineOccurrence records the reason', () async {
      final String occurrenceId = await createTriggeredOccurrence();

      final result = await engine.declineOccurrence(
        occurrenceId,
        reason: 'Não é mais necessário',
      );

      expect(
        result.valueOrNull?.status,
        OccurrenceStatus.declined,
      );

      expect(
        result.valueOrNull?.declineReason,
        'Não é mais necessário',
      );
    });

    test('markMissed transitions TRIGGERED -> MISSED', () async {
      final String occurrenceId = await createTriggeredOccurrence();

      final result = await engine.markMissed(occurrenceId);

      expect(
        result.valueOrNull?.status,
        OccurrenceStatus.missed,
      );
    });

    test(
      'snoozeOccurrence returns to SCHEDULED, increments count, reschedules forward',
      () async {
        final String occurrenceId = await createTriggeredOccurrence();

        final DateTime before = DateTime.now();

        final result =
            await engine.snoozeOccurrence(occurrenceId, snoozeMinutes: 10);

        expect(result.isSuccess, isTrue);
        expect(
          result.valueOrNull?.status,
          OccurrenceStatus.scheduled,
        );
        expect(
          result.valueOrNull?.snoozeCount,
          1,
        );
        expect(
          result.valueOrNull!.scheduledAt.isAfter(before),
          isTrue,
        );

        final events =
            await eventRepository.getEventsForOccurrence(occurrenceId);

        expect(
          events.valueOrNull!.map((e) => e.toStatus),
          <OccurrenceStatus>[
            OccurrenceStatus.snoozed,
            OccurrenceStatus.scheduled,
          ],
        );
      },
    );

    test('completing an already-completed occurrence fails', () async {
      final String occurrenceId = await createTriggeredOccurrence();

      await engine.completeOccurrence(occurrenceId);

      final secondAttempt = await engine.completeOccurrence(occurrenceId);

      expect(secondAttempt.isFailure, isTrue);
    });

    test(
      'completing a still-SCHEDULED occurrence fails (must be TRIGGERED first)',
      () async {
        final result = await engine.createTask(
          title: 'Tarefa',
          priority: TaskPriority.medium,
          recurrenceRule: const RecurrenceRule.none(),
          scheduledAt: DateTime(2026, 8, 24, 9, 0),
        );

        final String occurrenceId = (await occurrenceRepository
                .getActiveOccurrenceForTask(result.valueOrNull!.id))
            .valueOrNull!
            .id;

        final completeResult = await engine.completeOccurrence(occurrenceId);

        expect(completeResult.isFailure, isTrue);
      },
    );
  });
}
