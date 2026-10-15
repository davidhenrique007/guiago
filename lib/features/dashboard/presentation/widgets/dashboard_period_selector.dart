import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/dashboard_period.dart';

/// Segmented Hoje/Semana/Mês toggle. Built directly on Material
/// (not AppButton) — an exclusive 3-way pill selector doesn't map to
/// three separate buttons, and matches the "calm, disciplined"
/// identity (master spec §7) better than a default SegmentedButton.
class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  static const Map<DashboardPeriod, String> _labels = {
    DashboardPeriod.today: 'Hoje',
    DashboardPeriod.week: 'Semana',
    DashboardPeriod.month: 'Mês',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: DashboardPeriod.values.map((DashboardPeriod period) {
          final bool isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: AppDurations.medium,
                curve: AppCurves.standard,
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border:
                      isSelected ? Border.all(color: AppColors.border) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[period]!,
                  style: AppTypography.label.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
