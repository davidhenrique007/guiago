import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared pill-chip look for the Fase 6D selectors — same visual
/// language as DashboardPeriodSelector (Fase 6B).
class SelectorChip extends StatelessWidget {
  const SelectorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color:
                isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
