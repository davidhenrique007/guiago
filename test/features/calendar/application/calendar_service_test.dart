import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/calendar/application/calendar_service.dart';
import 'package:guiago/features/calendar/domain/calendar_day_snapshot.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

import '../../home/support/in_memory_repositories.dart';
import '../../performance/support/in_memory_repositories.dart';

void main() {
  late InMemoryTaskOccurrenceRepository occurrences;
  late InMemoryTaskRepository tasks;
  late CalendarService service;

  final DateTime day = DateTime(2026, 8, 14);

  Task task(String id, String title, {TaskPriority? priority}) {
    return Task(
      id: id,
      title: title,
      priority: priority ?? TaskPriority.low,
      recurrenceRule: const RecurrenceRule.none(),
      defaultToleranceMinutes: 15,
      defaultSnoozeMinutes: 10,
      createdAt: day,
      updatedAt: day,
      isArchived: false,
    );
  }

  TaskOccurrence occurrence(
    String id,
    String taskId,
    DateTime scheduledAt, {
    OccurrenceStatus status = OccurrenceStatus.scheduled,
  }) {
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
    service = CalendarService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
  });

  test('orders the day by scheduledAt and joins title and priority', () async {
    await tasks.saveTask(task('t1', 'Tarde', priority: TaskPriority.high));
    await tasks.saveTask(task('t2', 'Manhã'));
    await occurrences.saveOccurrence(
      occurrence('o1', 't1', DateTime(2026, 8, 14, 18)),
    );
    await occurrences.saveOccurrence(
      occurrence('o2', 't2', DateTime(2026, 8, 14, 8)),
    );

    final Result<CalendarDaySnapshot> result = await service.load(day);

    final CalendarDaySnapshot snapshot = result.valueOrNull!;
    expect(snapshot.day, day);
    expect(snapshot.items.map((i) => i.title), <String>['Manhã', 'Tarde']);
    expect(snapshot.items.last.priority, TaskPriority.high);
  });

  test('normalises a day given with a time of day', () async {
    final Result<CalendarDaySnapshot> result =
        await service.load(DateTime(2026, 8, 14, 22, 30));

    expect(result.valueOrNull!.day, DateTime(2026, 8, 14));
  });

  test('includes the first and last instants of the day only', () async {
    await tasks.saveTask(task('t1', 'Dentro'));
    await occurrences.saveOccurrence(
      occurrence('o1', 't1', DateTime(2026, 8, 14)),
    );
    await occurrences.saveOccurrence(
      occurrence('o2', 't1', DateTime(2026, 8, 14, 23, 59, 59)),
    );
    await occurrences.saveOccurrence(
      occurrence('o3', 't1', DateTime(2026, 8, 15)),
    );
    await occurrences.saveOccurrence(
      occurrence('o4', 't1', DateTime(2026, 8, 13, 23, 59, 59)),
    );

    final Result<CalendarDaySnapshot> result = await service.load(day);

    expect(
      result.valueOrNull!.items.map((i) => i.occurrenceId),
      <String>['o1', 'o2'],
    );
  });

  test('ignores cancelled occurrences', () async {
    await tasks.saveTask(task('t1', 'Tarefa'));
    await occurrences.saveOccurrence(
      occurrence(
        'o1',
        't1',
        DateTime(2026, 8, 14, 9),
        status: OccurrenceStatus.cancelled,
      ),
    );

    final Result<CalendarDaySnapshot> result = await service.load(day);

    expect(result.valueOrNull!.items, isEmpty);
  });

  test('ignores occurrences whose task no longer exists', () async {
    await occurrences.saveOccurrence(
      occurrence('o1', 'apagada', DateTime(2026, 8, 14, 9)),
    );

    final Result<CalendarDaySnapshot> result = await service.load(day);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.items, isEmpty);
  });

  test('a day without occurrences gives an empty list', () async {
    final Result<CalendarDaySnapshot> result = await service.load(day);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.items, isEmpty);
  });

  test('returns Fail when the repository fails', () async {
    occurrences.rangeFailure = const DatabaseFailure('boom');

    final Result<CalendarDaySnapshot> result = await service.load(day);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
