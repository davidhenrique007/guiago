import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/dashboard/presentation/screens/dashboard_screen.dart';
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
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 'task-1',
        title: 'Beber água',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> seedOccurrence(DateTime scheduledAt, OccurrenceStatus status) {
    return DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: 'occ-${scheduledAt.millisecondsSinceEpoch}',
        taskId: 'task-1',
        scheduledAt: scheduledAt,
        status: status,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpDashboardScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows zeroed metrics when there is no data', (
    WidgetTester tester,
  ) async {
    await pumpDashboardScreen(tester);

    expect(find.text('Desempenho'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Pontuação
    expect(find.text('Iniciante'), findsOneWidget); // Nível
    expect(find.text('0 dias'), findsOneWidget); // Sequência
    expect(find.text('—'), findsOneWidget); // Conclusão, sem dados
  });

  testWidgets('shows completion for today from a completed occurrence', (
    WidgetTester tester,
  ) async {
    await seedOccurrence(DateTime.now(), OccurrenceStatus.completed);

    await pumpDashboardScreen(tester);

    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('switching to Semana reveals data outside today', (
    WidgetTester tester,
  ) async {
    await seedOccurrence(
      DateTime.now().subtract(const Duration(days: 2)),
      OccurrenceStatus.completed,
    );

    await pumpDashboardScreen(tester);
    expect(find.text('—'), findsOneWidget); // Hoje: nada agendado hoje

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
  });
}
