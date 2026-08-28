import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  group('DriftSettingsRepository', () {
    test('getSettings returns Settings.initial when nothing was saved yet',
        () async {
      final result = await repository.getSettings();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, Settings.initial);
    });

    test('saveSettings then getSettings round-trips every field', () async {
      const Settings settings = Settings(
        userName: 'David',
        mainObjective: 'Estudar todos os dias',
        dayStartMinutes: 6 * 60,
        dayEndMinutes: 23 * 60,
        notificationsEnabled: false,
        ttsEnabled: true,
        defaultSnoozeMinutes: 5,
        defaultToleranceMinutes: 20,
        onboardingCompleted: true,
      );

      final saveResult = await repository.saveSettings(settings);
      expect(saveResult.isSuccess, isTrue);

      final loadResult = await repository.getSettings();
      expect(loadResult.valueOrNull, settings);
    });

    test(
        'saveSettings called twice overwrites the single row, never duplicates',
        () async {
      await repository.saveSettings(Settings.initial.copyWith(userName: 'A'));
      await repository.saveSettings(Settings.initial.copyWith(userName: 'B'));

      final result = await repository.getSettings();

      expect(result.valueOrNull?.userName, 'B');
    });
  });
}
