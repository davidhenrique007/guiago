import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTaskRepository(db);
  });

  tearDown(() => db.close());

  Task buildTask({
    String id = 'task-1',
    RecurrenceRule recurrenceRule = const RecurrenceRule.none(),
    bool isArchived = false,
  }) {
    final DateTime now = DateTime(2026, 8, 24, 9, 0);
    return Task(
      id: id,
      title: 'Estudar Flutter',
      description: 'Capítulo 3',
      priority: TaskPriority.high,
      recurrenceRule: recurrenceRule,
      defaultToleranceMinutes: 15,
      defaultSnoozeMinutes: 10,
      createdAt: now,
      updatedAt: now,
      isArchived: isArchived,
    );
  }

  group('DriftTaskRepository', () {
    test('saveTask then getTask round-trips a none-recurrence task', () async {
      final Task task = buildTask();
      final saveResult = await repository.saveTask(task);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repository.getTask(task.id);
      expect(getResult.valueOrNull, task);
    });

    test('round-trips a customDays recurrence rule', () async {
      final Task task = buildTask(
        recurrenceRule: const RecurrenceRule.customDays(
          weekdays: <int>{DateTime.monday, DateTime.wednesday, DateTime.friday},
        ),
      );
      await repository.saveTask(task);

      final getResult = await repository.getTask(task.id);
      expect(getResult.valueOrNull?.recurrenceRule, task.recurrenceRule);
    });

    test('getTask returns null for an unknown id', () async {
      final result = await repository.getTask('does-not-exist');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('getActiveTasks excludes archived tasks', () async {
      await repository.saveTask(buildTask(id: 'active'));
      await repository.saveTask(buildTask(id: 'archived', isArchived: true));

      final result = await repository.getActiveTasks();
      final ids = result.valueOrNull!.map((t) => t.id).toList();
      expect(ids, contains('active'));
      expect(ids, isNot(contains('archived')));
    });

    test('archiveTask marks the task archived', () async {
      final Task task = buildTask();
      await repository.saveTask(task);

      await repository.archiveTask(task.id);

      final getResult = await repository.getTask(task.id);
      expect(getResult.valueOrNull?.isArchived, isTrue);
    });

    test('deleteTask removes the row', () async {
      final Task task = buildTask();
      await repository.saveTask(task);

      await repository.deleteTask(task.id);

      final getResult = await repository.getTask(task.id);
      expect(getResult.valueOrNull, isNull);
    });
  });
}
