import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_card.dart';

/// A single metric on a surface: small label, large value, optional
/// detail line underneath. Introduced for the Fase 6 dashboard
/// (Score, Nível, Streak, Completion Rate) — reusable wherever else
/// the app needs the same "label + big number" shape (e.g. a future
/// Home summary).
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    this.detail,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs / 2),
            Text(detail!, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}
