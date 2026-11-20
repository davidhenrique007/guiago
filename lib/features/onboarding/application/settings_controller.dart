import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/settings_repository_provider.dart';
import '../domain/settings.dart';

/// Thrown into the [AsyncValue] when the settings cannot be read.
class SettingsLoadException implements Exception {
  const SettingsLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'SettingsLoadException: ${failure.message}';
}

/// Access to the saved [Settings] for screens outside onboarding
/// (Perfil, Nova tarefa, Progresso). Screens never talk to the
/// repository: they read here and change settings with [saveChange].
class SettingsController extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final Result<Settings> result =
        await ref.read(settingsRepositoryProvider).getSettings();
    return switch (result) {
      Success<Settings>(:final value) => value,
      Fail<Settings>(:final failure) => throw SettingsLoadException(failure),
    };
  }

  void refresh() => ref.invalidateSelf();

  /// Applies [change] to the current settings, saves them and, on
  /// success, publishes them to every screen watching this controller.
  /// On failure nothing changes.
  Future<Result<void>> saveChange(
    Settings Function(Settings current) change,
  ) async {
    final Settings current = await future;
    final Settings updated = change(current);
    final Result<void> result =
        await ref.read(settingsRepositoryProvider).saveSettings(updated);
    if (result.isSuccess) {
      state = AsyncData<Settings>(updated);
    }
    return result;
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);
