import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/application/settings_controller.dart';
import '../../features/onboarding/domain/settings.dart';
import 'app_theme_mode.dart';

/// The theme the user chose in Perfil → Aparência. Dark while the
/// settings load, which is also the look before it was a choice.
final Provider<AppThemeMode> themeModeProvider = Provider<AppThemeMode>((ref) {
  return switch (ref.watch(settingsControllerProvider)) {
    AsyncData<Settings>(:final value) => AppThemeMode.fromKey(value.themeMode),
    _ => AppThemeMode.dark,
  };
});
