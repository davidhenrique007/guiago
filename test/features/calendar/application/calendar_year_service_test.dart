import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/calendar/application/calendar_service.dart';
import 'package:guiago/features/calendar/domain/calendar_year_snapshot.dart';
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
  late DriftTaskOccurrenceRepository occurrences;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrences = DriftTaskOccurrenceRepository(db);
    final DriftTaskRepository tasks = DriftTaskRepository(db);
    service = CalendarService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
    final DateTime now = DateTime.now();
    await tasks.saveTask(
      Task(
        id: 't1',
        title: 'Estudar',
        priority: TaskPriority.high,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> seed(
    String id,
    DateTime at, {
    OccurrenceStatus status = OccurrenceStatus.scheduled,
  }) {
    return occurrences.saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: 't1',
        scheduledAt: at,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  test('counts the occurrences of each month of the year', () async {
    final int year = DateTime.now().year + 1;
    await seed('a', DateTime(year, 1, 1, 0, 1));
    await seed('b', DateTime(year, 1, 31, 23, 58));
    await seed('c', DateTime(year, 7, 15, 9));

    final CalendarYearSnapshot snapshot =
        (await service.loadYear(year)).valueOrNull!;

    expect(snapshot.year, year);
    expect(snapshot.countFor(1), 2);
    expect(snapshot.countFor(7), 1);
    expect(snapshot.countFor(2), 0);
  });

  test('ignores cancelled occurrences and other years', () async {
    final int year = DateTime.now().year + 1;
    await seed('a', DateTime(year, 3, 10, 9));
    await seed(
      'b',
      DateTime(year, 3, 11, 9),
      status: OccurrenceStatus.cancelled,
    );
    await seed('c', DateTime(year - 1, 12, 31, 23, 58));
    await seed('d', DateTime(year + 1, 1, 1, 0, 1));

    final CalendarYearSnapshot snapshot =
        (await service.loadYear(year)).valueOrNull!;

    expect(snapshot.taskCountByMonth, <int, int>{3: 1});
  });

  test('a year with nothing planned is empty', () async {
    final CalendarYearSnapshot snapshot =
        (await service.loadYear(DateTime.now().year + 3)).valueOrNull!;

    expect(snapshot.taskCountByMonth, isEmpty);
  });
}
