import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
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

class _FakeNotifier implements AlarmNotifier {
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

  Future<void> saveWindow(int start, int end) =>
      DriftSettingsRepository(db).saveSettings(
        Settings.initial.copyWith(dayStartMinutes: start, dayEndMinutes: end),
      );

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

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(_FakeNotifier()),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Calendar', () {
    testWidgets('shows the user day and marks tasks outside it', (
      WidgetTester tester,
    ) async {
      await saveWindow(7 * 60, 22 * 60);
      final DateTime now = DateTime.now();
      await seed(
        'a',
        'De madrugada',
        DateTime(now.year, now.month, now.day, 3),
      );
      await seed(
        'b',
        'Ao meio-dia',
        DateTime(now.year, now.month, now.day, 12),
      );

      await pump(tester, const CalendarScreen());

      expect(find.text('O teu dia: 07:00–22:00'), findsOneWidget);
      expect(find.text('Agendada · fora do teu dia'), findsOneWidget);
      expect(find.text('Agendada'), findsOneWidget);
    });

    testWidgets('the window follows the saved settings', (
      WidgetTester tester,
    ) async {
      await saveWindow(6 * 60 + 30, 23 * 60 + 55);

      await pump(tester, const CalendarScreen());

      expect(find.text('O teu dia: 06:30–23:55'), findsOneWidget);
    });
  });

  group('Task form', () {
    final DateTime future = DateTime.now().add(const Duration(days: 30));

    testWidgets('a future day starts at 09:00 when it is inside the day', (
      WidgetTester tester,
    ) async {
      await saveWindow(7 * 60, 22 * 60);

      await pump(tester, TaskCreateScreen(initialDate: future));

      expect(find.textContaining('Fora do teu dia'), findsNothing);
      expect(find.text('9:00 AM'), findsOneWidget);
    });

    testWidgets('a future day starts at the day start if 09:00 is before', (
      WidgetTester tester,
    ) async {
      await saveWindow(10 * 60, 22 * 60);

      await pump(tester, TaskCreateScreen(initialDate: future));

      expect(find.textContaining('Fora do teu dia'), findsNothing);
      expect(find.text('10:00 AM'), findsOneWidget);
    });

    testWidgets('a time outside the day shows a warning', (
      WidgetTester tester,
    ) async {
      await saveWindow(7 * 60, 22 * 60);
      final DateTime at = DateTime(future.year, future.month, future.day, 3);
      await seed('t1', 'Voo cedo', at);

      await pump(tester, const TaskCreateScreen(taskId: 't1'));

      expect(
        find.text('Fora do teu dia (07:00–22:00). Podes guardar na mesma.'),
        findsOneWidget,
      );
    });
  });
}
