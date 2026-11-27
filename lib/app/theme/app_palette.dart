import 'package:flutter/material.dart';

/// One complete set of GuiaGo colors. There are two: [dark] (the
/// original look, emerald on near-black) and [light].
///
/// Widgets never read a palette directly: they use the stable role
/// names of `AppColors`, which resolve to [current]. `PaletteScope`
/// switches [current] when the theme changes and rebuilds the app.
///
/// The light palette keeps every text role at WCAG AA contrast or
/// better on its surfaces (checked by `app_palette_test`).
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryVariant,
    required this.accent,
    required this.backgroundVoid,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.border,
    required this.borderSoft,
  });

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF2FBF83),
    primaryVariant: Color(0xFF1F8F60),
    accent: Color(0xFFE8A94C),
    backgroundVoid: Color(0xFF070B09),
    background: Color(0xFF0A100D),
    surface: Color(0xFF121A16),
    surfaceMuted: Color(0xFF1A241E),
    textPrimary: Color(0xFFF2F5F3),
    textSecondary: Color(0xFF8EA296),
    textTertiary: Color(0xFF5C6B63),
    textOnPrimary: Color(0xFF06120C),
    success: Color(0xFF2FBF83),
    warning: Color(0xFFE8A94C),
    error: Color(0xFFE2685F),
    border: Color(0xFF22302A),
    borderSoft: Color(0xFF182019),
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF167B52),
    primaryVariant: Color(0xFF0F5F3E),
    accent: Color(0xFF9A5B00),
    backgroundVoid: Color(0xFFE9EEEB),
    background: Color(0xFFF5F8F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEBF0ED),
    textPrimary: Color(0xFF0F1713),
    textSecondary: Color(0xFF4A5B52),
    textTertiary: Color(0xFF8A9A91),
    textOnPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF167B52),
    warning: Color(0xFF9A5B00),
    error: Color(0xFFC0392F),
    border: Color(0xFFD3DDD8),
    borderSoft: Color(0xFFE4EBE7),
  );

  /// The palette every `AppColors` role resolves to right now.
  static AppPalette current = dark;

  static void use(Brightness brightness) {
    current = brightness == Brightness.dark ? dark : light;
  }

  final Brightness brightness;
  final Color primary;
  final Color primaryVariant;
  final Color accent;
  final Color backgroundVoid;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color border;
  final Color borderSoft;
}
