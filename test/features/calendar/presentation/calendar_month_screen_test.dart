import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/core/utils/pt_date_labels.dart';
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

  Future<void> seed(String id, String title, DateTime at) async {
    final DateTime now = DateTime.now();
    await DriftTaskRepository(db).saveTask(
      Task(
        id: id,
        title: title,
        description: 'Descrição de $title',
        priority: TaskPriority.high,
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
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  String monthTitle(DateTime day) {
    final String name = PtDateLabels.months[day.month - 1];
    return '${name[0].toUpperCase()}${name.substring(1)} ${day.year}';
  }

  testWidgets('starts in the week view and can switch to the month', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byTooltip('Mês seguinte'), findsNothing);

    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mês seguinte'), findsOneWidget);
    expect(find.text(monthTitle(DateTime.now())), findsOneWidget);
  });

  testWidgets('selecting a day in the month shows its tasks', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    // Days 10 and 11 exist in every month.
    final int otherDay = now.day == 10 ? 11 : 10;
    await seed(
      't-today',
      'Tarefa de hoje',
      DateTime(now.year, now.month, now.day, 12),
    );
    await seed(
      't-other',
      'Tarefa de outro dia',
      DateTime(now.year, now.month, otherDay, 12),
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa de hoje'), findsOneWidget);
    expect(find.text('Tarefa de outro dia'), findsNothing);

    await tester.tap(find.text('$otherDay'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa de outro dia'), findsOneWidget);
    expect(find.text('Tarefa de hoje'), findsNothing);
  });

  testWidgets('the arrows change the month', (WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();

    final DateTime now = DateTime.now();
    await tester.tap(find.byTooltip('Mês seguinte'));
    await tester.pumpAndSettle();
    expect(
      find.text(monthTitle(DateTime(now.year, now.month + 1))),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(
      find.text(monthTitle(DateTime(now.year, now.month - 1))),
      findsOneWidget,
    );
  });

  testWidgets('tapping a task opens its read-only details', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    await seed(
      't1',
      'Estudar Flutter',
      DateTime(now.year, now.month, now.day, 12),
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Estudar Flutter'));
    await tester.pumpAndSettle();

    expect(find.text('Descrição de Estudar Flutter'), findsOneWidget);
    expect(find.text('Prioridade'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Repetição'), findsOneWidget);
    expect(find.text('Nenhuma'), findsOneWidget);
    expect(
      find.text('Para editar ou apagar, usa a aba Tarefas.'),
      findsOneWidget,
    );
  });
}
