import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';
import 'package:guiago/features/tasks/presentation/screens/tasks_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> seed(
    String id,
    String title,
    DateTime at,
    OccurrenceStatus status,
  ) async {
    final DateTime now = DateTime.now();
    await DriftTaskRepository(db).saveTask(
      Task(
        id: id,
        title: title,
        priority: TaskPriority.low,
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
        id: 'o-$id',
        taskId: id,
        scheduledAt: at,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a brand-new app invites the user to create the first task', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Ainda sem tarefas'), findsOneWidget);
    expect(find.text('Nova tarefa'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('shows today first and switches between the three lists', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime earlyToday = DateTime(now.year, now.month, now.day, 0, 1);
    await seed('t1', 'Tarefa de hoje', earlyToday, OccurrenceStatus.scheduled);
    await seed(
      't2',
      'Tarefa futura',
      now.add(const Duration(days: 3)),
      OccurrenceStatus.scheduled,
    );
    await seed(
      't3',
      'Tarefa feita',
      now.subtract(const Duration(days: 1)),
      OccurrenceStatus.completed,
    );

    await pumpScreen(tester);

    expect(find.text('Tarefa de hoje'), findsOneWidget);
    expect(find.text('Tarefa futura'), findsNothing);

    await tester.tap(find.text('Próximas'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa futura'), findsOneWidget);
    expect(find.text('Tarefa de hoje'), findsNothing);

    await tester.tap(find.text('Concluídas'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa feita'), findsOneWidget);
  });

  testWidgets('an empty segment explains itself when other lists have tasks', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    await seed(
      't1',
      'Só futura',
      now.add(const Duration(days: 3)),
      OccurrenceStatus.scheduled,
    );

    await pumpScreen(tester);

    expect(find.text('Sem tarefas para hoje'), findsOneWidget);
    expect(find.text('Ainda sem tarefas'), findsNothing);
  });
}
