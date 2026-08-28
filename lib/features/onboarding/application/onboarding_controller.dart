import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/settings_repository_provider.dart';
import '../domain/settings.dart';
import '../domain/settings_repository.dart';

/// Owns the in-progress [Settings] draft while the user goes through
/// onboarding, and persists it via [SettingsRepository] on
/// completion. Also doubles as the app's "what are the current
/// settings" source for Splash's routing decision (§22/§26).
class OnboardingController extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final SettingsRepository repository = ref.watch(settingsRepositoryProvider);
    final Result<Settings> result = await repository.getSettings();
    return result.when(
      success: (Settings settings) => settings,
      failure: (Failure failure) => Settings.initial,
    );
  }

  void updateUserName(String value) {
    _updateDraft((Settings s) => s.copyWith(userName: value));
  }

  void updateMainObjective(String value) {
    _updateDraft((Settings s) => s.copyWith(mainObjective: value));
  }

  void updateDayWindow({int? dayStartMinutes, int? dayEndMinutes}) {
    _updateDraft(
      (Settings s) => s.copyWith(
        dayStartMinutes: dayStartMinutes ?? s.dayStartMinutes,
        dayEndMinutes: dayEndMinutes ?? s.dayEndMinutes,
      ),
    );
  }

  void updateNotificationsEnabled(bool value) {
    _updateDraft((Settings s) => s.copyWith(notificationsEnabled: value));
  }

  void updateTtsEnabled(bool value) {
    _updateDraft((Settings s) => s.copyWith(ttsEnabled: value));
  }

  void updateDefaults({int? snoozeMinutes, int? toleranceMinutes}) {
    _updateDraft(
      (Settings s) => s.copyWith(
        defaultSnoozeMinutes: snoozeMinutes ?? s.defaultSnoozeMinutes,
        defaultToleranceMinutes: toleranceMinutes ?? s.defaultToleranceMinutes,
      ),
    );
  }

  /// Persists the draft with `onboardingCompleted = true`.
  Future<Result<void>> complete() async {
    final Settings? draft = switch (state) {
      AsyncData<Settings>(:final value) => value,
      _ => null,
    };
    if (draft == null) {
      return const Fail<void>(
        ValidationFailure('Onboarding state not ready yet'),
      );
    }

    final Settings completed = draft.copyWith(onboardingCompleted: true);
    final SettingsRepository repository = ref.read(settingsRepositoryProvider);
    final Result<void> result = await repository.saveSettings(completed);

    if (result.isSuccess) {
      state = AsyncData<Settings>(completed);
    }
    return result;
  }

  void _updateDraft(Settings Function(Settings current) transform) {
    final Settings? current = switch (state) {
      AsyncData<Settings>(:final value) => value,
      _ => null,
    };
    if (current == null) return;
    state = AsyncData<Settings>(transform(current));
  }
}

final AsyncNotifierProvider<OnboardingController, Settings>
    onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, Settings>(
  OnboardingController.new,
);
