import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/calendar_view_mode.dart';

/// Segmented Dia/Mês/Ano toggle, in the same look as the Dashboard's
/// period selector.
class CalendarViewSelector extends StatelessWidget {
  const CalendarViewSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CalendarViewMode selected;
  final ValueChanged<CalendarViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: CalendarViewMode.values.map((CalendarViewMode mode) {
          final bool isSelected = mode == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
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
                  mode.label,
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
