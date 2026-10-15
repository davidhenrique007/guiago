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

    await tester.tap(find.text('Criar tarefa'));
    await tester.pumpAndSettle();

    expect(find.text('Dá um título à tarefa.'), findsOneWidget);
    expect(find.byType(TaskCreateScreen), findsOneWidget);
  });

  testWidgets('creates the task and returns to the previous screen', (
    WidgetTester tester,
  ) async {
    await pumpFromHome(tester);

    await tester.enterText(find.byType(TextField).first, 'Beber água');
    await tester.tap(find.text('Criar tarefa'));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);

    final result = await DriftTaskRepository(db).getActiveTasks();
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.single.title, 'Beber água');
  });
}
