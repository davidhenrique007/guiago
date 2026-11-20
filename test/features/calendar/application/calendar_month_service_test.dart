import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/calendar/application/calendar_service.dart';
import 'package:guiago/features/calendar/domain/calendar_month_snapshot.dart';
import 'package:guiago/features/calendar/domain/calendar_task_detail.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late CalendarService service;
  late DriftTaskRepository tasks;
  late DriftTaskOccurrenceRepository occurrences;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasks = DriftTaskRepository(db);
    occurrences = DriftTaskOccurrenceRepository(db);
    service = CalendarService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
  });

  tearDown(() => db.close());

  Future<void> seedTask({String? description}) {
    final DateTime now = DateTime.now();
    return tasks.saveTask(
      Task(
        id: 't1',
        title: 'Estudar',
        description: description,
        priority: TaskPriority.high,
        recurrenceRule: const RecurrenceRule.daily(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      ),
    );
  }

  Future<void> seedOccurrence(
    String id,
    DateTime at, {
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    int snoozeCount = 0,
  }) {
    return occurrences.saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: 't1',
        scheduledAt: at,
        status: status,
        snoozeCount: snoozeCount,
        toleranceMinutes: 25,
      ),
    );
  }

  group('loadMonth', () {
    test('an empty month has no counts', () async {
      final CalendarMonthSnapshot snapshot =
          (await service.loadMonth(DateTime(2030, 6, 15))).valueOrNull!;

      expect(snapshot.month, DateTime(2030, 6));
      expect(snapshot.taskCountByDay, isEmpty);
      expect(snapshot.countFor(15), 0);
    });

    test('counts occurrences per day of the month', () async {
      await seedTask();
      await seedOccurrence('o1', DateTime(2030, 6, 15, 8));
      await seedOccurrence('o2', DateTime(2030, 6, 15, 20));
      await seedOccurrence('o3', DateTime(2030, 6, 20, 9));

      final CalendarMonthSnapshot snapshot =
          (await service.loadMonth(DateTime(2030, 6, 1))).valueOrNull!;

      expect(snapshot.countFor(15), 2);
      expect(snapshot.countFor(20), 1);
      expect(snapshot.countFor(16), 0);
    });

    test('ignores cancelled occurrences', () async {
      await seedTask();
      await seedOccurrence(
        'o1',
        DateTime(2030, 6, 15, 8),
        status: OccurrenceStatus.cancelled,
      );

      final CalendarMonthSnapshot snapshot =
          (await service.loadMonth(DateTime(2030, 6, 1))).valueOrNull!;

      expect(snapshot.taskCountByDay, isEmpty);
    });

    test('respects the month boundaries', () async {
      await seedTask();
      await seedOccurrence('o1', DateTime(2030, 6, 30, 23, 59));
      await seedOccurrence('o2', DateTime(2030, 7, 1, 0, 0));
      await seedOccurrence('o3', DateTime(2030, 5, 31, 23, 59));

      final CalendarMonthSnapshot june =
          (await service.loadMonth(DateTime(2030, 6, 10))).valueOrNull!;

      expect(june.taskCountByDay, <int, int>{30: 1});
    });
  });

  group('loadDetail', () {
    test('joins the occurrence with its task', () async {
      await seedTask(description: 'Capítulo 3');
      await seedOccurrence(
        'o1',
        DateTime(2030, 6, 15, 8),
        snoozeCount: 2,
      );

      final CalendarTaskDetail detail =
          (await service.loadDetail('o1')).valueOrNull!;

      expect(detail.title, 'Estudar');
      expect(detail.description, 'Capítulo 3');
      expect(detail.priority, TaskPriority.high);
      expect(detail.recurrenceRule, const RecurrenceRule.daily());
      expect(detail.status, OccurrenceStatus.scheduled);
      expect(detail.scheduledAt, DateTime(2030, 6, 15, 8));
      expect(detail.toleranceMinutes, 25);
      expect(detail.snoozeCount, 2);
    });

    test('fails for an unknown occurrence', () async {
      expect((await service.loadDetail('nope')).isFailure, isTrue);
    });

    test('fails when the task no longer exists', () async {
      await occurrences.saveOccurrence(
        TaskOccurrence(
          id: 'orphan',
          taskId: 'gone',
          scheduledAt: DateTime(2030, 6, 15, 8),
          status: OccurrenceStatus.scheduled,
          snoozeCount: 0,
          toleranceMinutes: 15,
        ),
      );

      expect((await service.loadDetail('orphan')).isFailure, isTrue);
    });
  });
}
