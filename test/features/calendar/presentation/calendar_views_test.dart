import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/calendar/presentation/screens/calendar_screen.dart';
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

class _RecordingNotifier implements AlarmNotifier {
  final List<DateTime> scheduled = <DateTime>[];

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    scheduled.add(scheduledAt);
    return const Success<void>(null);
  }

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
  late _RecordingNotifier notifier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = _RecordingNotifier();
  });

  tearDown(() => db.close());

  Future<void> seed(String id, String title, DateTime at) async {
    final DateTime now = DateTime.now();
    await DriftTaskRepository(db).saveTask(
      Task(
        id: id,
        title: title,
        priority: TaskPriority.medium,
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

  Future<void> pumpCalendar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.calendar,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.calendar,
          name: AppRoutes.calendarName,
          builder: (BuildContext context, GoRouterState state) =>
              const CalendarScreen(),
        ),
        GoRoute(
          path: AppRoutes.taskCreate,
          name: AppRoutes.taskCreateName,
          builder: (BuildContext context, GoRouterState state) {
            final Object? extra = state.extra;
            return TaskCreateScreen(
              initialDate: extra is DateTime ? extra : null,
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has the Dia, Mês and Ano selector and starts on Dia', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(tester);

    expect(find.text('Dia'), findsOneWidget);
    expect(find.text('Mês'), findsOneWidget);
    expect(find.text('Ano'), findsOneWidget);
    expect(find.byTooltip('Dia anterior'), findsOneWidget);
  });

  testWidgets('the Dia view lists several tasks in chronological order', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    await seed('t3', 'Terceira', at(15, 0));
    await seed('t1', 'Primeira', at(7, 30));
    await seed('t2', 'Segunda', at(10, 30));

    await pumpCalendar(tester);

    expect(find.text('Tarefas do dia (3)'), findsOneWidget);
    final double first = tester.getTopLeft(find.text('Primeira')).dy;
    final double second = tester.getTopLeft(find.text('Segunda')).dy;
    final double third = tester.getTopLeft(find.text('Terceira')).dy;
    expect(first, lessThan(second));
    expect(second, lessThan(third));
    expect(find.text('07:30'), findsOneWidget);
  });

  testWidgets('the day arrows move the selected day', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    await seed(
      't1',
      'Amanhã cedo',
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8),
    );
    await pumpCalendar(tester);
    expect(find.text('Amanhã cedo'), findsNothing);

    await tester.tap(find.byTooltip('Dia seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('Amanhã cedo'), findsOneWidget);

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Amanhã cedo'), findsNothing);
  });

  testWidgets('"Nova tarefa" is offered from today on, not for the past', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(tester);
    expect(find.text('Nova tarefa'), findsOneWidget);

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Nova tarefa'), findsNothing);

    await tester.tap(find.byTooltip('Dia seguinte'));
    await tester.tap(find.byTooltip('Dia seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('Nova tarefa'), findsOneWidget);
  });

  testWidgets('the Ano view shows the months and navigates between years', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(tester);
    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();

    final int year = DateTime.now().year;
    expect(find.text('$year'), findsOneWidget);
    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Dezembro'), findsOneWidget);

    await tester.tap(find.byTooltip('Ano seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('${year + 1}'), findsOneWidget);
  });

  testWidgets('a month with tasks is marked, and opens in the Mês view', (
    WidgetTester tester,
  ) async {
    final int year = DateTime.now().year + 1;
    await seed('t1', 'Viagem', DateTime(year, 8, 20, 9));
    await pumpCalendar(tester);

    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ano seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('1 tarefa'), findsOneWidget);

    await tester.tap(find.text('Agosto'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mês seguinte'), findsOneWidget);

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(find.text('Viagem'), findsOneWidget);
  });

  testWidgets('plans a task for January of next year from the Ano view', (
    WidgetTester tester,
  ) async {
    final int year = DateTime.now().year + 1;
    await pumpCalendar(tester);

    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ano seguinte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Janeiro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskCreateScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Planear o ano');
    await tester.tap(find.text('Guardar tarefa'));
    await tester.pumpAndSettle();

    // The alarm was scheduled for the chosen future date, at 09:00.
    expect(notifier.scheduled, <DateTime>[DateTime(year, 1, 1, 9)]);
    // Back on the Calendar, the new task shows on that day.
    expect(find.byType(TaskCreateScreen), findsNothing);
    expect(find.text('Planear o ano'), findsOneWidget);
  });
}
