import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/presentation/screens/task_create_screen.dart';

/// Same fake as alarm_screen_test.dart: a widget test has no real
/// platform channel for flutter_local_notifications, so the real
/// NotificationService would hang pumpAndSettle forever waiting for
/// a response that never arrives.
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

  Future<void> pumpFromHome(WidgetTester tester) async {
    // Tall surface: the form is a lazy ListView, and the chips and the
    // save button sit below the default 600-px test viewport.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.pushNamed(AppRoutes.taskCreateName),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.taskCreate,
          name: AppRoutes.taskCreateName,
          builder: (BuildContext context, GoRouterState state) =>
              const TaskCreateScreen(),
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

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a validation message when the title is empty', (
    WidgetTester tester,
  ) async {
    await pumpFromHome(tester);

    await tester.tap(find.text('Guardar tarefa'));
    await tester.pumpAndSettle();

    expect(find.text('Dá um título à tarefa.'), findsOneWidget);
    expect(find.byType(TaskCreateScreen), findsOneWidget);
  });

  testWidgets('creates the task and returns to the previous screen', (
    WidgetTester tester,
  ) async {
    await pumpFromHome(tester);

    await tester.enterText(find.byType(TextField).first, 'Beber água');
    await tester.tap(find.text('Guardar tarefa'));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);

    final result = await DriftTaskRepository(db).getActiveTasks();
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.single.title, 'Beber água');
  });

  testWidgets('shows the Settings defaults as the selected chips', (
    WidgetTester tester,
  ) async {
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(
        defaultToleranceMinutes: 30,
        defaultSnoozeMinutes: 5,
      ),
    );

    await pumpFromHome(tester);

    expect(find.text('Tolerância'), findsOneWidget);
    expect(find.text('Snooze padrão'), findsOneWidget);
    expect(find.text('Baixa'), findsOneWidget);
    expect(find.text('Média'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
  });

  testWidgets('saves the Settings defaults when the chips are untouched', (
    WidgetTester tester,
  ) async {
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(
        defaultToleranceMinutes: 30,
        defaultSnoozeMinutes: 5,
      ),
    );
    await pumpFromHome(tester);

    await tester.enterText(find.byType(TextField).first, 'Ler');
    await tester.tap(find.text('Guardar tarefa'));
    await tester.pumpAndSettle();

    final task =
        (await DriftTaskRepository(db).getActiveTasks()).valueOrNull!.single;
    expect(task.defaultToleranceMinutes, 30);
    expect(task.defaultSnoozeMinutes, 5);
  });

  testWidgets('a chosen tolerance and snooze override the defaults', (
    WidgetTester tester,
  ) async {
    await pumpFromHome(tester);

    await tester.enterText(find.byType(TextField).first, 'Correr');
    await tester.tap(find.text('60 min')); // only a tolerance option
    await tester.pump();
    // 30 min exists in both rows; the second one is the snooze row.
    await tester.tap(find.text('30 min').last);
    await tester.pump();
    await tester.tap(find.text('Guardar tarefa'));
    await tester.pumpAndSettle();

    final task =
        (await DriftTaskRepository(db).getActiveTasks()).valueOrNull!.single;
    expect(task.defaultToleranceMinutes, 60);
    expect(task.defaultSnoozeMinutes, 30);
  });
}
