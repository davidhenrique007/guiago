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

  // A fixed reference clock injected into the service — no dependency
  // on the real "today".
  final DateTime now = DateTime(2030, 6, 15, 12, 0);

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

  Future<void> seedTask(String id, String title, {bool archived = false}) {
    return tasks.saveTask(
      Task(
        id: id,
        title: title,
        priority: TaskPriority.medium,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: now,
        updatedAt: now,
        isArchived: archived,
      ),
    );
  }

  Future<void> seedOccurrence(
    String id,
    String taskId,
    DateTime at,
    OccurrenceStatus status, {
    DateTime? completedAt,
  }) {
    return occurrences.saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: taskId,
        scheduledAt: at,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
        completedAt: completedAt,
      ),
    );
  }

  test('a new app has three empty lists', () async {
    final snapshot = (await service.load(now: now)).valueOrNull!;
    expect(snapshot.isEmpty, isTrue);
  });

  test('splits pending occurrences into today and upcoming', () async {
    await seedTask('t1', 'Hoje cedo');
    await seedTask('t2', 'Hoje tarde');
    await seedTask('t3', 'Amanhã');
    await seedOccurrence(
      'o1',
      't1',
      DateTime(2030, 6, 15, 8),
      OccurrenceStatus.scheduled,
    );
    await seedOccurrence(
      'o2',
      't2',
      DateTime(2030, 6, 15, 23, 30),
      OccurrenceStatus.scheduled,
    );
    await seedOccurrence(
      'o3',
      't3',
      DateTime(2030, 6, 16, 0, 5),
      OccurrenceStatus.scheduled,
    );

    final TasksSnapshot snapshot = (await service.load(now: now)).valueOrNull!;

    expect(
      snapshot.today.map((TaskListItem i) => i.title),
      <String>['Hoje cedo', 'Hoje tarde'],
    );
    expect(
      snapshot.upcoming.map((TaskListItem i) => i.title),
      <String>['Amanhã'],
    );
    expect(snapshot.completed, isEmpty);
  });

  test('an overdue pending occurrence still counts as today', () async {
    await seedTask('t1', 'Atrasada');
    await seedOccurrence(
      'o1',
      't1',
      DateTime(2030, 6, 10, 9),
      OccurrenceStatus.triggered,
    );

    final TasksSnapshot snapshot = (await service.load(now: now)).valueOrNull!;

    expect(snapshot.today.single.status, OccurrenceStatus.triggered);
  });

  test('resolved occurrences go to completed, most recent first', () async {
    await seedTask('t1', 'Antiga');
    await seedTask('t2', 'Recente');
    await seedTask('t3', 'Perdida');
    await seedOccurrence(
      'o1',
      't1',
      DateTime(2030, 6, 1, 9),
      OccurrenceStatus.completed,
      completedAt: DateTime(2030, 6, 1, 9, 5),
    );
    await seedOccurrence(
      'o2',
      't2',
      DateTime(2030, 6, 14, 9),
      OccurrenceStatus.completed,
      completedAt: DateTime(2030, 6, 14, 9, 5),
    );
    await seedOccurrence(
      'o3',
      't3',
      DateTime(2030, 6, 10, 9),
      OccurrenceStatus.missed,
    );

    final TasksSnapshot snapshot = (await service.load(now: now)).valueOrNull!;

    expect(
      snapshot.completed.map((TaskListItem i) => i.title),
      <String>['Recente', 'Perdida', 'Antiga'],
    );
    expect(snapshot.today, isEmpty);
  });

  test('ignores cancelled occurrences and archived tasks', () async {
    await seedTask('t1', 'Cancelada');
    await seedTask('t2', 'Arquivada', archived: true);
    await seedOccurrence(
      'o1',
      't1',
      DateTime(2030, 6, 15, 9),
      OccurrenceStatus.cancelled,
    );
    await seedOccurrence(
      'o2',
      't2',
      DateTime(2030, 6, 15, 10),
      OccurrenceStatus.scheduled,
    );

    final TasksSnapshot snapshot = (await service.load(now: now)).valueOrNull!;

    expect(snapshot.isEmpty, isTrue);
  });

  test('completed list is capped by completedLimit', () async {
    final TasksService capped = TasksService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
      completedLimit: 2,
    );
    await seedTask('t1', 'Tarefa');
    for (int i = 1; i <= 4; i++) {
      await seedOccurrence(
        'o$i',
        't1',
        DateTime(2030, 6, i, 9),
        OccurrenceStatus.completed,
        completedAt: DateTime(2030, 6, i, 9, 1),
      );
    }

    final TasksSnapshot snapshot = (await capped.load(now: now)).valueOrNull!;

    expect(snapshot.completed, hasLength(2));
    expect(snapshot.completed.first.scheduledAt, DateTime(2030, 6, 4, 9));
  });
}
