import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';
import 'package:guiago/features/tasks/presentation/screens/task_create_screen.dart';
import 'package:guiago/features/tasks/presentation/screens/tasks_screen.dart';

/// A widget test has no real platform channel for
/// flutter_local_notifications (same reason as alarm_screen_test).
class _FakeAlarmNotifier implements AlarmNotifier {
  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> cancel(int id) async => const Success<void>(null);

  @override
  Future<Result<void>> cancelAll() async => const Success<void>(null);

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> seedTodayTask() async {
    final DateTime now = DateTime.now();
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 't1',
        title: 'Estudar Flutter',
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
        id: 'o1',
        taskId: 't1',
        // Always "today", whatever the hour the suite runs at.
        scheduledAt: DateTime(now.year, now.month, now.day, 0, 1),
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpTasks(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.tasks,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.tasks,
          name: AppRoutes.tasksName,
          builder: (BuildContext context, GoRouterState state) =>
              const TasksScreen(),
        ),
        GoRoute(
          path: AppRoutes.taskEdit,
          name: AppRoutes.taskEditName,
          builder: (BuildContext context, GoRouterState state) =>
              TaskCreateScreen(taskId: state.pathParameters['taskId']),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(_FakeAlarmNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a pending task offers Editar and Apagar', (
    WidgetTester tester,
  ) async {
    await seedTodayTask();
    await pumpTasks(tester);

    await tester.tap(find.text('Estudar Flutter'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Apagar'), findsOneWidget);
  });

  testWidgets('Apagar asks for confirmation and removes the task', (
    WidgetTester tester,
  ) async {
    await seedTodayTask();
    await pumpTasks(tester);

    await tester.tap(find.text('Estudar Flutter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Apagar tarefa?'), findsOneWidget);
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    final task = (await DriftTaskRepository(db).getTask('t1')).valueOrNull!;
    expect(task.isArchived, isTrue);
    final TaskOccurrence occurrence =
        (await DriftTaskOccurrenceRepository(db).getOccurrence('o1'))
            .valueOrNull!;
    expect(occurrence.status, OccurrenceStatus.cancelled);
    expect(find.text('Estudar Flutter'), findsNothing);
    expect(find.text('Ainda sem tarefas'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the task', (
    WidgetTester tester,
  ) async {
    await seedTodayTask();
    await pumpTasks(tester);

    await tester.tap(find.text('Estudar Flutter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final task = (await DriftTaskRepository(db).getTask('t1')).valueOrNull!;
    expect(task.isArchived, isFalse);
    expect(find.text('Estudar Flutter'), findsOneWidget);
  });

  testWidgets('Editar opens the form filled in and saves the changes', (
    WidgetTester tester,
  ) async {
    await seedTodayTask();
    await pumpTasks(tester);

    await tester.tap(find.text('Estudar Flutter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar tarefa'), findsOneWidget);
    expect(find.text('Estudar Flutter'), findsOneWidget); // prefilled title

    await tester.enterText(find.byType(TextField).first, 'Estudar Dart');
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();

    final task = (await DriftTaskRepository(db).getTask('t1')).valueOrNull!;
    expect(task.title, 'Estudar Dart');
    // Back on the list, which was reloaded.
    expect(find.text('Estudar Dart'), findsOneWidget);
  });
}
