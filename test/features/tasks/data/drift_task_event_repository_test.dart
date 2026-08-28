import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/tasks/data/drift_task_event_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_event.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late DriftTaskEventRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTaskEventRepository(db);

    // Events reference a task and an occurrence via foreign keys.
    final DateTime now = DateTime(2026, 8, 24, 9, 0);
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 'task-1',
        title: 'Estudar Flutter',
        priority: TaskPriority.medium,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      ),
    );
    await DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: 'occ-1',
        taskId: 'task-1',
        scheduledAt: now,
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  });

  tearDown(() => db.close());

  group('DriftTaskEventRepository', () {
    test('recordEvent then getEventsForOccurrence returns it back', () async {
      final TaskEvent event = TaskEvent(
        id: 'evt-1',
        taskId: 'task-1',
        occurrenceId: 'occ-1',
        fromStatus: OccurrenceStatus.scheduled,
        toStatus: OccurrenceStatus.triggered,
        occurredAt: DateTime(2026, 8, 24, 9, 5),
      );
      final recordResult = await repository.recordEvent(event);
      expect(recordResult.isSuccess, isTrue);

      final result = await repository.getEventsForOccurrence('occ-1');
      expect(result.valueOrNull, <TaskEvent>[event]);
    });

    test('history is returned oldest first', () async {
      await repository.recordEvent(
        TaskEvent(
          id: 'evt-1',
          taskId: 'task-1',
          occurrenceId: 'occ-1',
          fromStatus: OccurrenceStatus.scheduled,
          toStatus: OccurrenceStatus.triggered,
          occurredAt: DateTime(2026, 8, 24, 9, 5),
        ),
      );
      await repository.recordEvent(
        TaskEvent(
          id: 'evt-2',
          taskId: 'task-1',
          occurrenceId: 'occ-1',
          fromStatus: OccurrenceStatus.triggered,
          toStatus: OccurrenceStatus.completed,
          occurredAt: DateTime(2026, 8, 24, 9, 6),
        ),
      );

      final result = await repository.getEventsForOccurrence('occ-1');
      final ids = result.valueOrNull!.map((e) => e.id).toList();
      expect(ids, <String>['evt-1', 'evt-2']);
    });
  });
}
