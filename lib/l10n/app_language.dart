import 'package:flutter/widgets.dart';

/// The languages the app can be shown in. [code] is what is stored in
/// the settings; [label] is the language's own name, so a user can
/// always find theirs whatever language the app is in now.
enum AppLanguage {
  portuguese('pt', 'Português'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);

  /// An unknown or missing code falls back to Portuguese, the language
  /// every install had before it became a choice.
  static AppLanguage fromCode(String? code) {
    for (final AppLanguage language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.portuguese;
  }
}
