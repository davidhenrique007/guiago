import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';

/// Linear progress indicator used for onboarding step progress and
/// (later, Fase 6) daily/weekly completion progress. Animates value
/// changes instead of jumping, per master spec §9 (motion communicates
/// progress).
class AppProgress extends StatelessWidget {
  const AppProgress({required this.value, super.key});

  /// 0.0–1.0
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
        duration: AppDurations.medium,
        curve: AppCurves.standard,
        builder: (BuildContext context, double animatedValue, _) {
          return LinearProgressIndicator(
            value: animatedValue,
            minHeight: 6,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          );
        },
      ),
    );
  }
}
