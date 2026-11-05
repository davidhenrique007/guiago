import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/application/settings_controller.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';

void main() {
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

  test('loads the initial settings when nothing was saved', () async {
    final Settings settings =
        await container.read(settingsControllerProvider.future);

    expect(settings, Settings.initial);
  });

  test('loads what was saved, and refresh re-reads it', () async {
    await container.read(settingsControllerProvider.future);

    await DriftSettingsRepository(db)
        .saveSettings(Settings.initial.copyWith(userName: 'Ana'));
    container.read(settingsControllerProvider.notifier).refresh();
    final Settings settings =
        await container.read(settingsControllerProvider.future);

    expect(settings.userName, 'Ana');
  });
}
