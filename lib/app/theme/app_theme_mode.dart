import 'package:flutter/material.dart';

/// How the user wants the app to look: always light, always dark, or
/// following the phone. [key] is what is stored in the settings.
enum AppThemeMode {
  system('system', 'Sistema', ThemeMode.system),
  light('light', 'Claro', ThemeMode.light),
  dark('dark', 'Escuro', ThemeMode.dark);

  const AppThemeMode(this.key, this.label, this.themeMode);

  final String key;
  final String label;
  final ThemeMode themeMode;

  /// An unknown or missing key falls back to dark, the look every
  /// install had before the theme became a choice.
  static AppThemeMode fromKey(String? key) {
    for (final AppThemeMode mode in AppThemeMode.values) {
      if (mode.key == key) return mode;
    }
    return AppThemeMode.dark;
  }
}
