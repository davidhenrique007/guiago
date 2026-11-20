import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/application/settings_controller.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/data/settings_repository_provider.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/onboarding/domain/settings_repository.dart';

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<Result<Settings>> getSettings() async =>
      const Success<Settings>(Settings.initial);

  @override
  Future<Result<void>> saveSettings(Settings settings) async =>
      const Fail<void>(DatabaseFailure('disk full'));
}

void main() {
  group('SettingsController.saveChange', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('saves the change and publishes it to the state', () async {
      final SettingsController controller =
          container.read(settingsControllerProvider.notifier);
      await container.read(settingsControllerProvider.future);

      final Result<void> result = await controller.saveChange(
        (Settings s) => s.copyWith(
          userName: 'Ana',
          mainObjective: 'Estudar',
          defaultSnoozeMinutes: 15,
        ),
      );

      expect(result.isSuccess, isTrue);
      final Settings inState =
          await container.read(settingsControllerProvider.future);
      expect(inState.userName, 'Ana');
      expect(inState.defaultSnoozeMinutes, 15);

      final Settings inDatabase =
          (await DriftSettingsRepository(db).getSettings()).valueOrNull!;
      expect(inDatabase.userName, 'Ana');
      expect(inDatabase.mainObjective, 'Estudar');
      expect(inDatabase.defaultSnoozeMinutes, 15);
    });

    test('keeps what was not changed', () async {
      final SettingsController controller =
          container.read(settingsControllerProvider.notifier);
      await container.read(settingsControllerProvider.future);

      await controller.saveChange((Settings s) => s.copyWith(userName: 'Ana'));
      await controller
          .saveChange((Settings s) => s.copyWith(ttsEnabled: false));

      final Settings settings =
          await container.read(settingsControllerProvider.future);
      expect(settings.userName, 'Ana');
      expect(settings.ttsEnabled, isFalse);
      expect(settings.defaultToleranceMinutes, 15);
    });
  });

  test('a failed save leaves the state untouched', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          _FailingSettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final SettingsController controller =
        container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);

    final Result<void> result = await controller.saveChange(
      (Settings s) => s.copyWith(userName: 'Ana'),
    );

    expect(result.isFailure, isTrue);
    final Settings settings =
        await container.read(settingsControllerProvider.future);
    expect(settings.userName, '');
  });
}
