import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/application/settings_controller.dart';
import '../features/onboarding/domain/settings.dart';
import 'app_language.dart';

/// The language the user chose in Perfil → Idioma. Portuguese while the
/// settings load, which is also what every install had before.
final Provider<AppLanguage> languageProvider = Provider<AppLanguage>((ref) {
  return switch (ref.watch(settingsControllerProvider)) {
    AsyncData<Settings>(:final value) =>
      AppLanguage.fromCode(value.languageCode),
    _ => AppLanguage.portuguese,
  };
});
