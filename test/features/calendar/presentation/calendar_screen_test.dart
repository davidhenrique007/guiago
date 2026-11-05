import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> seedTask(String id, String title) {
    return DriftTaskRepository(db).saveTask(
      Task(
        id: id,
        title: title,
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      ),
    );
  }

  Future<void> seedOccurrence(String id, String taskId, DateTime at) {
    return DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: taskId,
        scheduledAt: at,
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on today and shows an empty state', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Calendário'), findsOneWidget);
    expect(find.text('Sem tarefas neste dia'), findsOneWidget);
  });

  testWidgets('selecting another day of the week changes the list', (
    WidgetTester tester,
  ) async {
    final DateTime today = DateTime.now();
    // Another day of the current week: Tuesday, or Monday if today is
    // already Tuesday.
    final int otherWeekday =
        today.weekday == DateTime.tuesday ? DateTime.monday : DateTime.tuesday;
    final DateTime other = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1) + (otherWeekday - 1),
    );

    await seedTask('t-today', 'Tarefa de hoje');
    await seedTask('t-other', 'Tarefa de outro dia');
    await seedOccurrence(
      'o-today',
      't-today',
      DateTime(today.year, today.month, today.day, 12),
    );
    await seedOccurrence(
      'o-other',
      't-other',
      DateTime(other.year, other.month, other.day, 12),
    );

    await pumpScreen(tester);

    expect(find.text('Tarefa de hoje'), findsOneWidget);
    expect(find.text('Tarefa de outro dia'), findsNothing);

    await tester.tap(find.text('${other.day}'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa de outro dia'), findsOneWidget);
    expect(find.text('Tarefa de hoje'), findsNothing);
  });
}
