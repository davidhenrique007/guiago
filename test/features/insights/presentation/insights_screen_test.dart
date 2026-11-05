import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/insights/presentation/screens/insights_screen.dart';
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

  /// A completed occurrence yesterday at [hour]; yesterday is always
  /// inside the 30-day window whatever time the test runs.
  Future<void> seedCompleted(String id, String taskId, int hour) {
    final DateTime now = DateTime.now();
    final DateTime at = DateTime(now.year, now.month, now.day - 1, hour);
    return DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: taskId,
        scheduledAt: at,
        completedAt: at,
        status: OccurrenceStatus.completed,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpInsights(WidgetTester tester) async {
    // Tests the child route directly, as the Perfil link only
    // arrives in Lote 5.
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.profileInsights,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.profile,
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('PERFIL')),
          routes: <RouteBase>[
            GoRoute(
              path: 'insights',
              name: AppRoutes.profileInsightsName,
              builder: (BuildContext context, GoRouterState state) =>
                  const InsightsScreen(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no data shows the empty states', (
    WidgetTester tester,
  ) async {
    await pumpInsights(tester);

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('RESUMO GERAL'), findsOneWidget);
    expect(find.text('Ainda sem dados suficientes'), findsOneWidget);
    expect(find.text('Ainda sem tarefas concluídas'), findsOneWidget);
  });

  testWidgets('shows the peak window and the most completed tasks', (
    WidgetTester tester,
  ) async {
    await seedTask('t1', 'Estudar programação');
    for (int i = 0; i < 4; i++) {
      await seedCompleted('a$i', 't1', 8);
      await seedCompleted('b$i', 't1', 9);
    }
    await seedCompleted('c0', 't1', 10);
    await seedCompleted('c1', 't1', 10);

    await pumpInsights(tester);

    expect(find.text('08:00 – 11:00'), findsOneWidget);
    expect(find.text('Estudar programação'), findsOneWidget);
    expect(find.text('10'), findsNWidgets(2)); // summary + top task
    expect(find.text('Ainda sem dados suficientes'), findsNothing);
  });
}
