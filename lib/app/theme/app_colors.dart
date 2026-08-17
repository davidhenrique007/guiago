import 'package:flutter/material.dart';

/// GuiaGo color foundation.
///
/// Placeholder palette for Fase 0 — Fase 1 (Design System + Onboarding)
/// will refine this against the visual reference direction (calm,
/// disciplined, premium — see master spec §7-8) without hardcoding
/// colors anywhere else in the app.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2F6F5E);
  static const Color primaryVariant = Color(0xFF1F4E42);
  static const Color accent = Color(0xFFE8A33D);

  // Surfaces
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFEFEC);

  // Text
  static const Color textPrimary = Color(0xFF141414);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // State
  static const Color success = Color(0xFF3E9142);
  static const Color warning = Color(0xFFE8A33D);
  static const Color error = Color(0xFFC94B4B);

  // Borders / dividers
  static const Color border = Color(0xFFE0E0DC);
}
