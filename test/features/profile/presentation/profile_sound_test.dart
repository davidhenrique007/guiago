import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/design_system/components/app_bottom_sheet.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';
import 'package:guiago/features/scheduler/application/alarm_preferences_applier.dart';
import 'package:guiago/features/scheduler/data/alarm_preferences_providers.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/scheduler/domain/alarm_sound_previewer.dart';
import 'package:guiago/features/scheduler/domain/notification_sound.dart';

class _FakeNotifier implements AlarmNotifier {
  int cancelAllCalls = 0;

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
  Future<Result<void>> cancelAll() async {
    cancelAllCalls++;
    return const Success<void>(null);
  }

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

class _FakePreviewer implements AlarmSoundPreviewer {
  final List<NotificationSound> played = <NotificationSound>[];
  final List<bool> vibrations = <bool>[];

  @override
  Future<Result<void>> preview(
    NotificationSound sound, {
    required bool vibration,
  }) async {
    played.add(sound);
    vibrations.add(vibration);
    return const Success<void>(null);
  }
}

void main() {
  late AppDatabase db;
  late _FakeNotifier notifier;
  late _FakePreviewer previewer;
  late int rearmed;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = _FakeNotifier();
    previewer = _FakePreviewer();
    rearmed = 0;
  });

  tearDown(() => db.close());

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(userName: 'Ana'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifier),
          alarmSoundPreviewerProvider.overrideWithValue(previewer),
          alarmPreferencesApplierProvider.overrideWithValue(
            AlarmPreferencesApplier(
              notifier: notifier,
              rearm: () async => rearmed++,
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Settings> saved() async =>
      (await DriftSettingsRepository(db).getSettings()).valueOrNull!;

  testWidgets('the notification group shows the sound and the vibration', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('NOTIFICAÇÕES'), findsOneWidget);
    expect(find.text('Som da notificação'), findsOneWidget);
    expect(find.text('Som do sistema'), findsOneWidget);
    expect(find.text('Vibração'), findsOneWidget);
    expect(find.text('Ligada'), findsOneWidget);
  });

  testWidgets('hearing a sound does not choose it', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Som da notificação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ouvir GuiaGo — Alerta'));
    await tester.pumpAndSettle();

    expect(previewer.played, <NotificationSound>[NotificationSound.alert]);
    expect(previewer.vibrations, <bool>[true]);
    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect((await saved()).notificationSound, 'system');
  });

  testWidgets('choosing a sound saves it and re-arms the alarms', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Som da notificação'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text('GuiaGo — Despertar'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await saved()).notificationSound, 'wake');
    expect(find.text('GuiaGo — Despertar'), findsOneWidget);
    expect(rearmed, 1);
  });

  testWidgets('"Sem som" has no play button', (WidgetTester tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Som da notificação'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ouvir Sem som'), findsNothing);
    expect(find.byTooltip('Ouvir GuiaGo — Suave'), findsOneWidget);
  });

  testWidgets('the vibration switch persists and re-arms the alarms', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    // Switches in order: Notificações, Vibração, Voz (TTS).
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect((await saved()).vibrationEnabled, isFalse);
    expect(find.text('Desligada'), findsOneWidget);
    expect(rearmed, 1);
  });

  testWidgets('switching notifications off cancels the pending alarms', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect((await saved()).notificationsEnabled, isFalse);
    expect(notifier.cancelAllCalls, 1);
    expect(rearmed, 0);
  });

  testWidgets('switching notifications back on re-arms the alarms', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect((await saved()).notificationsEnabled, isTrue);
    expect(rearmed, 1);
  });
}
