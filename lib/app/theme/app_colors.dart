import 'package:flutter/material.dart';

import 'app_palette.dart';

/// GuiaGo color roles. Widgets reference roles (`primary`, `surface`,
/// `textSecondary`...), never raw hex values; each role resolves to the
/// active [AppPalette] (dark or light), so the whole app re-themes from
/// `app_palette.dart`.
///
/// These are getters, not constants: they cannot be used in `const`
/// expressions. Build the widget without `const` instead.
abstract final class AppColors {
  // Brand
  static Color get primary => AppPalette.current.primary;
  static Color get primaryVariant => AppPalette.current.primaryVariant;
  static Color get accent => AppPalette.current.accent;

  // Surfaces (darkest to lightest in the dark palette)
  static Color get backgroundVoid => AppPalette.current.backgroundVoid;
  static Color get background => AppPalette.current.background;
  static Color get surface => AppPalette.current.surface;
  static Color get surfaceMuted => AppPalette.current.surfaceMuted;

  // Text
  static Color get textPrimary => AppPalette.current.textPrimary;
  static Color get textSecondary => AppPalette.current.textSecondary;

  /// Decorative only (disabled hints, captions on cards). It does not
  /// reach WCAG AA contrast on [surface] — never use it for text the
  /// user must read.
  static Color get textTertiary => AppPalette.current.textTertiary;
  static Color get textOnPrimary => AppPalette.current.textOnPrimary;

  // State
  static Color get success => AppPalette.current.success;
  static Color get warning => AppPalette.current.warning;
  static Color get error => AppPalette.current.error;

  // Borders / dividers
  static Color get border => AppPalette.current.border;
  static Color get borderSoft => AppPalette.current.borderSoft;
}
