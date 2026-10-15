import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/home/application/home_service.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

import '../../performance/support/in_memory_repositories.dart';
import '../support/in_memory_repositories.dart';

void main() {
  late InMemoryTaskOccurrenceRepository occurrences;
  late InMemoryTaskRepository tasks;
  late InMemorySettingsRepository settings;
  late HomeService service;

  final DateTime now = DateTime(2026, 3, 15, 12);

  Task task(String id, String title) {
    return Task(
      id: id,
      title: title,
      priority: TaskPriority.low,
      recurrenceRule: const RecurrenceRule.none(),
      defaultToleranceMinutes: 15,
      defaultSnoozeMinutes: 10,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
    );
  }

  TaskOccurrence occurrence(
    String id,
    String taskId,
    DateTime scheduledAt,
    OccurrenceStatus status,
  ) {
    return TaskOccurrence(
      id: id,
      taskId: taskId,
      scheduledAt: scheduledAt,
      status: status,
      snoozeCount: 0,
      toleranceMinutes: 15,
    );
  }

  setUp(() {
    occurrences = InMemoryTaskOccurrenceRepository();
    tasks = InMemoryTaskRepository();
    settings = InMemorySettingsRepository();
    service = HomeService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
      settingsRepository: settings,
    );
  });

  group('HomeService.load', () {
    test('returns the saved user name with no tasks today', () async {
      settings.settings = Settings.initial.copyWith(userName: 'Ana');

      final result = await service.load(now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.userName, 'Ana');
      expect(snapshot.todayTasks, isEmpty);
      expect(snapshot.nextTask, isNull);
      expect(snapshot.hasTasksToday, isFalse);
    });

    test("joins today's occurrences with their task's title and priority",
        () async {
      await tasks.saveTask(task('t1', 'Beber água'));
      await occurrences.saveOccurrence(
        occurrence(
            'o1', 't1', DateTime(2026, 3, 15, 9), OccurrenceStatus.scheduled,),
      );

      final result = await service.load(now: now);
      final snapshot = result.valueOrNull!;

      expect(snapshot.todayTasks, hasLength(1));
      expect(snapshot.todayTasks.single.title, 'Beber água');
      expect(snapshot.todayTasks.single.priority, TaskPriority.low);
    });

    test('drops cancelled occurrences and occurrences of deleted tasks',
        () async {
      await tasks.saveTask(task('t1', 'Tarefa viva'));
      await occurrences.saveOccurrence(
        occurrence(
            'o1', 't1', DateTime(2026, 3, 15, 9), OccurrenceStatus.scheduled,),
      );
      await occurrences.saveOccurrence(
        occurrence(
          'o2',
          't1',
          DateTime(2026, 3, 15, 10),
          OccurrenceStatus.cancelled,
        ),
      );
      // 't2' never saved — its task was deleted after being scheduled.
      await occurrences.saveOccurrence(
        occurrence(
            'o3', 't2', DateTime(2026, 3, 15, 11), OccurrenceStatus.scheduled,),
      );

      final result = await service.load(now: now);

      expect(result.valueOrNull!.todayTasks, hasLength(1));
      expect(result.valueOrNull!.todayTasks.single.occurrenceId, 'o1');
    });

    test('nextTask is the first unresolved item, skipping resolved ones',
        () async {
      await tasks.saveTask(task('t1', 'Primeira'));
      await tasks.saveTask(task('t2', 'Segunda'));
      await occurrences.saveOccurrence(
        occurrence(
          'o1',
          't1',
          DateTime(2026, 3, 15, 8),
          OccurrenceStatus.completed,
        ),
      );
      await occurrences.saveOccurrence(
        occurrence(
            'o2', 't2', DateTime(2026, 3, 15, 9), OccurrenceStatus.scheduled,),
      );

      final result = await service.load(now: now);

      expect(result.valueOrNull!.nextTask?.title, 'Segunda');
    });

    test('nextTask is null when everything today is resolved', () async {
      await tasks.saveTask(task('t1', 'Única'));
      await occurrences.saveOccurrence(
        occurrence(
          'o1',
          't1',
          DateTime(2026, 3, 15, 8),
          OccurrenceStatus.completed,
        ),
      );

      final result = await service.load(now: now);

      expect(result.valueOrNull!.nextTask, isNull);
      expect(result.valueOrNull!.completedCount, 1);
      expect(result.valueOrNull!.progress, 1.0);
    });

    test('only includes occurrences scheduled today', () async {
      await tasks.saveTask(task('t1', 'Ontem'));
      await tasks.saveTask(task('t2', 'Hoje'));
      await occurrences.saveOccurrence(
        occurrence(
          'o1',
          't1',
          DateTime(2026, 3, 14, 23),
          OccurrenceStatus.scheduled,
        ),
      );
      await occurrences.saveOccurrence(
        occurrence(
            'o2', 't2', DateTime(2026, 3, 15, 1), OccurrenceStatus.scheduled,),
      );

      final result = await service.load(now: now);

      expect(result.valueOrNull!.todayTasks, hasLength(1));
      expect(result.valueOrNull!.todayTasks.single.title, 'Hoje');
    });
  });
}
