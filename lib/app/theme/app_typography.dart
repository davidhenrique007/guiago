import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// GuiaGo typography scale. Three voices, each with one job:
///
/// * Fraunces (serif) — display and titles: warmth and character.
/// * IBM Plex Sans — body text and buttons: neutral and readable.
/// * IBM Plex Mono — labels, times and numbers: precision, discipline.
///
/// Not `const` because `GoogleFonts.*` resolves the font at call time
/// (see `app_theme.dart`, which builds its `TextTheme` at runtime for
/// the same reason).
abstract final class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get titleLarge => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get titleMedium => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// Small caption / field label.
  static TextStyle get label => GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
        letterSpacing: 0.8,
      );

  /// Button text.
  static TextStyle get button => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Times and figures (09:41, 84%, 12 dias).
  static TextStyle get mono => GoogleFonts.ibmPlexMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
      );
}
