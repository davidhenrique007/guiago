import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/application/onboarding_controller.dart';
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

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('starts with Settings.initial when nothing is saved yet', () async {
    final Settings settings =
        await container.read(onboardingControllerProvider.future);

    expect(settings, Settings.initial);
  });

  test('updateUserName updates the in-memory draft immediately', () async {
    await container.read(onboardingControllerProvider.future);

    container
        .read(onboardingControllerProvider.notifier)
        .updateUserName('David');

    final Settings? draft =
        switch (container.read(onboardingControllerProvider)) {
      AsyncData<Settings>(:final value) => value,
      _ => null,
    };
    expect(draft?.userName, 'David');
  });

  test('complete() persists the draft with onboardingCompleted = true',
      () async {
    await container.read(onboardingControllerProvider.future);
    final OnboardingController controller =
        container.read(onboardingControllerProvider.notifier);

    controller.updateUserName('David');
    controller.updateMainObjective('Treinar 4x por semana');

    final Result<void> result = await controller.complete();

    expect(result.isSuccess, isTrue);
    final Settings? state =
        switch (container.read(onboardingControllerProvider)) {
      AsyncData<Settings>(:final value) => value,
      _ => null,
    };
    expect(state?.onboardingCompleted, isTrue);
    expect(state?.userName, 'David');
    expect(state?.mainObjective, 'Treinar 4x por semana');
  });
}
