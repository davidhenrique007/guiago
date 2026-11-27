import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_typography.dart';

/// Assembles a [ThemeData] from the GuiaGo design tokens, once per
/// palette. The two themes are built from their own palette (never from
/// the "current" one), so both can exist at the same time and Flutter
/// picks between them with the user's theme mode.
///
/// Screens and widgets should read styling from `Theme.of(context)` or
/// the token classes directly (`AppColors`, `AppTypography`,
/// `AppSpacing`) — never hardcode a color or font size inline.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData light() => _build(AppPalette.light);

  static ThemeData _build(AppPalette p) {
    final bool isDark = p.brightness == Brightness.dark;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.textOnPrimary,
      secondary: p.accent,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.error,
      outline: p.border,
    );

    // Same color choice as the AppTypography roles, but for this palette.
    TextStyle on(TextStyle style, Color color) => style.copyWith(color: color);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      textTheme: TextTheme(
        displayLarge: on(AppTypography.displayLarge, p.textPrimary),
        titleLarge: on(AppTypography.titleLarge, p.textPrimary),
        titleMedium: on(AppTypography.titleMedium, p.textPrimary),
        bodyLarge: on(AppTypography.bodyLarge, p.textPrimary),
        bodyMedium: on(AppTypography.bodyMedium, p.textSecondary),
        labelLarge: on(AppTypography.label, p.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: on(AppTypography.titleLarge, p.textPrimary),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
    );
  }
}
