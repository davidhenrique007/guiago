import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum AppBadgeTone { neutral, success, warning, error }

/// Small status/label pill — streaks, priority, state chips.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.neutral,
    super.key,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (tone) {
      AppBadgeTone.neutral => AppColors.textSecondary,
      AppBadgeTone.success => AppColors.success,
      AppBadgeTone.warning => AppColors.warning,
      AppBadgeTone.error => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }
}
