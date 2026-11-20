import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/tasks/application/tasks_service.dart';
import 'package:guiago/features/tasks/application/tasks_view_state.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late TasksService service;
  late DriftTaskRepository tasks;
  late DriftTaskOccurrenceRepository occurrences;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasks = DriftTaskRepository(db);
    occurrences = DriftTaskOccurrenceRepository(db);
    service = TasksService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
  });

  tearDown(() => db.close());

  Future<void> seed({
    bool archived = false,
    OccurrenceStatus? status,
    DateTime? at,
  }) async {
    final DateTime now = DateTime.now();
    await tasks.saveTask(
      Task(
        id: 't1',
        title: 'Tarefa',
        priority: TaskPriority.high,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 20,
        defaultSnoozeMinutes: 5,
        createdAt: now,
        updatedAt: now,
        isArchived: archived,
      ),
    );
    if (status != null) {
      await occurrences.saveOccurrence(
        TaskOccurrence(
          id: 'o1',
          taskId: 't1',
          scheduledAt: at ?? DateTime(2030, 1, 1, 9),
          status: status,
          snoozeCount: 0,
          toleranceMinutes: 20,
        ),
      );
    }
  }

  test('returns the task and the pending time', () async {
    final DateTime at = DateTime(2030, 5, 5, 14, 30);
    await seed(status: OccurrenceStatus.scheduled, at: at);

    final TaskEditDraft draft = (await service.loadForEdit('t1')).valueOrNull!;

    expect(draft.task.title, 'Tarefa');
    expect(draft.task.defaultSnoozeMinutes, 5);
    expect(draft.scheduledAt, at);
  });

  test('has no editable time when the occurrence is already resolved',
      () async {
    await seed(status: OccurrenceStatus.completed);

    final TaskEditDraft draft = (await service.loadForEdit('t1')).valueOrNull!;

    expect(draft.scheduledAt, isNull);
  });

  test('fails for a missing or archived task', () async {
    expect((await service.loadForEdit('nope')).isFailure, isTrue);

    await seed(archived: true);
    expect((await service.loadForEdit('t1')).isFailure, isTrue);
  });
}
