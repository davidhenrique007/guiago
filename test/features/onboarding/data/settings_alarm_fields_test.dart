import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/onboarding/domain/settings_repository.dart';
import 'package:guiago/features/scheduler/data/settings_alarm_preferences_source.dart';
import 'package:guiago/features/scheduler/domain/alarm_preferences.dart';
import 'package:guiago/features/scheduler/domain/notification_sound.dart';

class _BrokenRepository implements SettingsRepository {
  @override
  Future<Result<Settings>> getSettings() async =>
      const Fail<Settings>(DatabaseFailure('nope'));

  @override
  Future<Result<void>> saveSettings(Settings settings) async =>
      const Fail<void>(DatabaseFailure('nope'));
}

void main() {
  group('sound and vibration persistence', () {
    late AppDatabase db;
    late DriftSettingsRepository repository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftSettingsRepository(db);
    });

    tearDown(() => db.close());

    test('the defaults are the system sound, with vibration', () async {
      final Settings settings = (await repository.getSettings()).valueOrNull!;

      expect(settings.notificationSound, 'system');
      expect(settings.vibrationEnabled, isTrue);
    });

    test('a chosen sound and vibration survive a save and a reload', () async {
      await repository.saveSettings(
        Settings.initial.copyWith(
          notificationSound: 'wake',
          vibrationEnabled: false,
        ),
      );

      final Settings settings = (await repository.getSettings()).valueOrNull!;
      expect(settings.notificationSound, 'wake');
      expect(settings.vibrationEnabled, isFalse);
    });

    test('the alarm preferences source reads them from the settings', () async {
      await repository.saveSettings(
        Settings.initial.copyWith(
          notificationsEnabled: false,
          notificationSound: 'soft',
          vibrationEnabled: false,
        ),
      );

      final AlarmPreferences prefs =
          await SettingsAlarmPreferencesSource(repository).current();

      expect(prefs.notificationsEnabled, isFalse);
      expect(prefs.sound, NotificationSound.soft);
      expect(prefs.vibrationEnabled, isFalse);
    });

    test('an unknown saved sound reads as the system sound', () async {
      await repository.saveSettings(
        Settings.initial.copyWith(notificationSound: 'removed-sound'),
      );

      final AlarmPreferences prefs =
          await SettingsAlarmPreferencesSource(repository).current();

      expect(prefs.sound, NotificationSound.system);
    });
  });

  test('unreadable settings fall back to the old behaviour', () async {
    final AlarmPreferences prefs =
        await SettingsAlarmPreferencesSource(_BrokenRepository()).current();

    expect(prefs.notificationsEnabled, isTrue);
    expect(prefs.sound, NotificationSound.system);
    expect(prefs.vibrationEnabled, isTrue);
  });

  test('a database from before these settings is upgraded and keeps its data',
      () async {
    final AppDatabase db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('''
            CREATE TABLE settings (
              id INTEGER NOT NULL DEFAULT 0,
              user_name TEXT NOT NULL DEFAULT '',
              main_objective TEXT NOT NULL DEFAULT '',
              day_start_minutes INTEGER NOT NULL DEFAULT 420,
              day_end_minutes INTEGER NOT NULL DEFAULT 1320,
              notifications_enabled INTEGER NOT NULL DEFAULT 1,
              tts_enabled INTEGER NOT NULL DEFAULT 1,
              default_snooze_minutes INTEGER NOT NULL DEFAULT 10,
              default_tolerance_minutes INTEGER NOT NULL DEFAULT 15,
              onboarding_completed INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (id)
            )
          ''');
          rawDb.execute(
            'INSERT INTO settings (id, user_name, default_snooze_minutes) '
            "VALUES (0, 'David', 5)",
          );
          rawDb.execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(db.close);

    final Settings settings =
        (await DriftSettingsRepository(db).getSettings()).valueOrNull!;

    expect(settings.userName, 'David');
    expect(settings.defaultSnoozeMinutes, 5);
    expect(settings.notificationSound, 'system');
    expect(settings.vibrationEnabled, isTrue);
  });
}
