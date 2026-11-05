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

/// Read access to the saved [Settings] for screens outside onboarding
/// (Perfil, Nova tarefa). Screens never talk to the repository.
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
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);
