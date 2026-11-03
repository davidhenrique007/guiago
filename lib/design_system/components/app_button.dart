import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// GuiaGo's single button component. Every tappable "primary action"
/// in the app (complete task, save onboarding step, confirm dialog)
/// goes through this widget instead of a raw [ElevatedButton] — one
/// place to keep sizing, motion, and disabled/loading states
/// consistent (master spec §7).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final Color background = switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => AppColors.surfaceMuted,
      AppButtonVariant.ghost => Colors.transparent,
    };
    final Color foreground = switch (variant) {
      AppButtonVariant.primary => AppColors.textOnPrimary,
      AppButtonVariant.secondary => AppColors.textPrimary,
      AppButtonVariant.ghost => AppColors.primary,
    };

    return AnimatedOpacity(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      opacity: _isDisabled && !isLoading ? 0.5 : 1,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background,
            disabledForegroundColor: foreground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: AppTypography.button.copyWith(color: foreground),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
