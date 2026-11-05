import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/home/presentation/screens/home_screen.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
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

  Future<void> seedOccurrence(
    String id,
    String taskId,
    DateTime scheduledAt,
    OccurrenceStatus status,
  ) {
    return DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: id,
        taskId: taskId,
        scheduledAt: scheduledAt,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpHomeScreen(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
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

  testWidgets('shows the greeting and an empty state with nothing today', (
    WidgetTester tester,
  ) async {
    await DriftSettingsRepository(
      db,
    ).saveSettings(Settings.initial.copyWith(userName: 'Ana'));

    await pumpHomeScreen(tester);

    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.text('Sem tarefas para hoje'), findsOneWidget);
    expect(find.text('Tudo em dia por agora.'), findsOneWidget);
  });

  testWidgets('shows the next task and progress from seeded occurrences', (
    WidgetTester tester,
  ) async {
    await seedTask('task-1', 'Beber água');
    await seedOccurrence(
      'occ-1',
      'task-1',
      DateTime.now(),
      OccurrenceStatus.scheduled,
    );

    await pumpHomeScreen(tester);

    expect(find.text('Beber água'), findsNWidgets(2)); // próxima + lista
    expect(find.text('0 de 1 concluídas'), findsOneWidget);
  });
}
