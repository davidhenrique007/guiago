import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/insights/application/insights_service.dart';
import 'package:guiago/features/insights/domain/insights_snapshot.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

import '../../home/support/in_memory_repositories.dart';
import '../../performance/support/in_memory_repositories.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 15, 12);

  late InMemoryTaskOccurrenceRepository occurrences;
  late InMemoryTaskRepository tasks;
  late InsightsService service;
  int seq = 0;

  Task task(String id, String title) => Task(
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

  Future<void> complete(
    String taskId,
    int hour, {
    int daysAgo = 1,
    OccurrenceStatus status = OccurrenceStatus.completed,
  }) {
    final DateTime at = DateTime(2026, 3, 15 - daysAgo, hour);
    return occurrences.saveOccurrence(
      TaskOccurrence(
        id: 'o${seq++}',
        taskId: taskId,
        scheduledAt: at,
        completedAt: at,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  setUp(() {
    seq = 0;
    occurrences = InMemoryTaskOccurrenceRepository();
    tasks = InMemoryTaskRepository();
    service = InsightsService(
      occurrenceRepository: occurrences,
      taskRepository: tasks,
    );
  });

  test('without data: empty histogram, no peak, no top tasks', () async {
    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(s.completionsByHour, List<int>.filled(24, 0));
    expect(s.totalCompletions, 0);
    expect(s.peak, isNull);
    expect(s.topTasks, isEmpty);
  });

  test('only completed occurrences count', () async {
    await tasks.saveTask(task('t1', 'A'));
    await complete('t1', 9);
    await complete('t1', 9, status: OccurrenceStatus.missed);
    await complete('t1', 9, status: OccurrenceStatus.declined);
    await complete('t1', 9, status: OccurrenceStatus.scheduled);

    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(s.totalCompletions, 1);
    expect(s.completionsByHour[9], 1);
  });

  test('finds the peak once there are enough completions', () async {
    await tasks.saveTask(task('t1', 'A'));
    for (int i = 0; i < 4; i++) {
      await complete('t1', 8);
      await complete('t1', 9);
    }
    await complete('t1', 10);
    await complete('t1', 10);

    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(s.totalCompletions, 10);
    expect(s.peak, const ProductivityPeak(startHour: 8, endHour: 10));
  });

  test('ignores completions older than the 30-day window', () async {
    await tasks.saveTask(task('t1', 'A'));
    await complete('t1', 9, daysAgo: 2);
    await complete('t1', 9, daysAgo: 45);

    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(s.totalCompletions, 1);
  });

  test('top tasks: top 3, most completed first, ties by title', () async {
    await tasks.saveTask(task('a', 'Alfa'));
    await tasks.saveTask(task('b', 'Beta'));
    await tasks.saveTask(task('c', 'Gama'));
    await tasks.saveTask(task('d', 'Delta'));
    for (int i = 0; i < 5; i++) {
      await complete('c', 8);
    }
    for (int i = 0; i < 2; i++) {
      await complete('b', 8);
      await complete('a', 8);
      await complete('d', 8);
    }

    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(
      s.topTasks.map((t) => '${t.title}:${t.completedCount}'),
      <String>['Gama:5', 'Alfa:2', 'Beta:2'],
    );
  });

  test('a deleted task is not listed', () async {
    await tasks.saveTask(task('a', 'Alfa'));
    await complete('a', 8);
    await complete('apagada', 8);

    final InsightsSnapshot s = (await service.load(now: now)).valueOrNull!;

    expect(s.topTasks.map((t) => t.title), <String>['Alfa']);
    // The hour histogram still counts the completion itself.
    expect(s.totalCompletions, 2);
  });

  test('propagates a repository failure', () async {
    occurrences.rangeFailure = const DatabaseFailure('boom');

    final Result<InsightsSnapshot> result = await service.load(now: now);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
