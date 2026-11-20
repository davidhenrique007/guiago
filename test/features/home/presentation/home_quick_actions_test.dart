import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/home/presentation/screens/home_screen.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

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

  Future<void> seedDueOccurrence() async {
    final DateTime now = DateTime.now();
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 't1',
        title: 'Beber água',
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
        scheduledAt: now,
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(_FakeAlarmNotifier()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<TaskOccurrence> occurrence() async =>
      (await DriftTaskOccurrenceRepository(db).getOccurrence('o1'))
          .valueOrNull!;

  testWidgets('the Home no longer offers to create a task', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a due task shows Concluir and Adiar', (
    WidgetTester tester,
  ) async {
    await seedDueOccurrence();

    await pumpHome(tester);

    expect(find.text('Concluir'), findsNWidgets(2)); // próxima + lista
    expect(find.text('Adiar'), findsNWidgets(2));
  });

  testWidgets('tapping Concluir completes the occurrence', (
    WidgetTester tester,
  ) async {
    await seedDueOccurrence();
    await pumpHome(tester);

    await tester.tap(find.text('Concluir').first);
    await tester.pumpAndSettle();

    expect((await occurrence()).status, OccurrenceStatus.completed);
    expect(find.text('1 de 1 concluídas'), findsOneWidget);
  });

  testWidgets('tapping Adiar pushes the occurrence forward', (
    WidgetTester tester,
  ) async {
    await seedDueOccurrence();
    await pumpHome(tester);

    await tester.tap(find.text('Adiar').first);
    await tester.pumpAndSettle();

    final TaskOccurrence after = await occurrence();
    expect(after.status, OccurrenceStatus.scheduled);
    expect(after.snoozeCount, 1);
  });
}
