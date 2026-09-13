import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/alarms/application/alarm_providers.dart';
import 'package:guiago/features/alarms/domain/tts_speaker.dart';
import 'package:guiago/features/alarms/presentation/screens/alarm_screen.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

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

class _FakeTtsSpeaker implements TtsSpeaker {
  @override
  Future<Result<void>> speak(String text) async => const Success<void>(null);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);
}

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
    await DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: 'occ-1',
        taskId: 'task-1',
        scheduledAt: DateTime.now(),
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpAlarmScreen(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/alarm/occ-1',
      routes: <RouteBase>[
        GoRoute(
          path: '/alarm/:occurrenceId',
          builder: (BuildContext context, GoRouterState state) => AlarmScreen(
            occurrenceId: state.pathParameters['occurrenceId']!,
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('HOME')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(_FakeAlarmNotifier()),
          ttsServiceProvider.overrideWithValue(_FakeTtsSpeaker()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the task title and the three action buttons', (
    WidgetTester tester,
  ) async {
    await pumpAlarmScreen(tester);

    expect(find.text('Beber água'), findsOneWidget);
    expect(find.text('Concluída'), findsOneWidget);
    expect(find.text('Adiar'), findsOneWidget);
    expect(find.text('Não vou'), findsOneWidget);
  });

  testWidgets('tapping Concluída resolves the occurrence and navigates home', (
    WidgetTester tester,
  ) async {
    await pumpAlarmScreen(tester);

    await tester.tap(find.text('Concluída'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);

    final result =
        await DriftTaskOccurrenceRepository(db).getOccurrence('occ-1');
    expect(result.valueOrNull?.status, OccurrenceStatus.completed);
  });
}
