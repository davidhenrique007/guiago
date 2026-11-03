import 'package:flutter/material.dart';

/// GuiaGo color foundation — dark-first palette taken from the
/// approved screen designs (emerald on near-black, amber and coral as
/// signal colors). Master spec §7: calm, focused, premium.
///
/// Token names are stable: widgets reference roles (`primary`,
/// `surface`, `textSecondary`...), never raw hex values, so the whole
/// app can be re-themed from this one file.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2FBF83); // emerald
  static const Color primaryVariant = Color(0xFF1F8F60); // emerald-deep
  static const Color accent = Color(0xFFE8A94C); // amber

  // Surfaces (darkest to lightest)
  static const Color backgroundVoid = Color(0xFF070B09);
  static const Color background = Color(0xFF0A100D);
  static const Color surface = Color(0xFF121A16);
  static const Color surfaceMuted = Color(0xFF1A241E);

  // Text
  static const Color textPrimary = Color(0xFFF2F5F3);
  static const Color textSecondary = Color(0xFF8EA296);

  /// Decorative only (disabled hints, captions on cards). It does not
  /// reach WCAG AA contrast on [surface] — never use it for text the
  /// user must read.
  static const Color textTertiary = Color(0xFF5C6B63);
  static const Color textOnPrimary = Color(0xFF06120C);

  // State
  static const Color success = Color(0xFF2FBF83);
  static const Color warning = Color(0xFFE8A94C);
  static const Color error = Color(0xFFE2685F); // coral

  // Borders / dividers
  static const Color border = Color(0xFF22302A);
  static const Color borderSoft = Color(0xFF182019);
}
