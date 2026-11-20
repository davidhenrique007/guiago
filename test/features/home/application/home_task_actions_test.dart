import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/home/application/home_task_actions.dart';
import 'package:guiago/features/tasks/application/task_engine.dart';
import 'package:guiago/features/tasks/data/drift_task_event_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftTaskOccurrenceRepository occurrences;
  late HomeTaskActions actions;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasks = DriftTaskRepository(db);
    occurrences = DriftTaskOccurrenceRepository(db);
    actions = HomeTaskActions(
      taskEngine: TaskEngine(
        taskRepository: tasks,
        occurrenceRepository: occurrences,
        eventRepository: DriftTaskEventRepository(db),
      ),
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
  });

  tearDown(() => db.close());

  Future<void> seed({
    required DateTime at,
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    int snoozeMinutes = 10,
  }) async {
    final DateTime now = DateTime.now();
    await tasks.saveTask(
      Task(
        id: 't1',
        title: 'Tarefa',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: snoozeMinutes,
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      ),
    );
    await occurrences.saveOccurrence(
      TaskOccurrence(
        id: 'o1',
        taskId: 't1',
        scheduledAt: at,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<TaskOccurrence> occurrence() async =>
      (await occurrences.getOccurrence('o1')).valueOrNull!;

  group('complete', () {
    test('completes a scheduled occurrence through triggered', () async {
      await seed(at: DateTime(2030, 1, 1, 9));

      final Result<void> result = await actions.complete('o1');

      expect(result.isSuccess, isTrue);
      final TaskOccurrence after = await occurrence();
      expect(after.status, OccurrenceStatus.completed);
      expect(after.triggeredAt, isNotNull);
      expect(after.completedAt, isNotNull);
    });

    test('completes an occurrence that is already triggered', () async {
      await seed(
        at: DateTime(2020, 1, 1, 9),
        status: OccurrenceStatus.triggered,
      );

      final Result<void> result = await actions.complete('o1');

      expect(result.isSuccess, isTrue);
      expect((await occurrence()).status, OccurrenceStatus.completed);
    });

    test('fails for an already resolved occurrence', () async {
      await seed(
        at: DateTime(2020, 1, 1, 9),
        status: OccurrenceStatus.missed,
      );

      final Result<void> result = await actions.complete('o1');

      expect(result.isFailure, isTrue);
      expect((await occurrence()).status, OccurrenceStatus.missed);
    });

    test('fails for an unknown occurrence', () async {
      final Result<void> result = await actions.complete('nope');
      expect(result.isFailure, isTrue);
    });
  });

  group('snooze', () {
    test('pushes a due occurrence forward by the task snooze', () async {
      await seed(at: DateTime(2020, 1, 1, 9), snoozeMinutes: 25);
      final DateTime before = DateTime.now();

      final Result<void> result = await actions.snooze('o1');

      expect(result.isSuccess, isTrue);
      final TaskOccurrence after = await occurrence();
      expect(after.status, OccurrenceStatus.scheduled);
      expect(after.snoozeCount, 1);
      final Duration pushed = after.scheduledAt.difference(before);
      expect(pushed.inMinutes, inInclusiveRange(24, 25));
    });

    test('refuses to snooze an occurrence that is not due yet', () async {
      final DateTime future = DateTime(2030, 1, 1, 9);
      await seed(at: future);

      final Result<void> result = await actions.snooze('o1');

      expect(result.isFailure, isTrue);
      final TaskOccurrence after = await occurrence();
      expect(after.status, OccurrenceStatus.scheduled);
      expect(after.scheduledAt, future);
      expect(after.snoozeCount, 0);
    });

    test('fails for an unknown occurrence', () async {
      final Result<void> result = await actions.snooze('nope');
      expect(result.isFailure, isTrue);
    });
  });
}
