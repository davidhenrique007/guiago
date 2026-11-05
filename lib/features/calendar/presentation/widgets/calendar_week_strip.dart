import 'package:flutter/material.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';

/// Monday-to-Sunday strip for the week that contains [selectedDay].
/// Only days of that week can be selected (no week navigation).
class CalendarWeekStrip extends StatelessWidget {
  const CalendarWeekStrip({
    required this.selectedDay,
    required this.onSelected,
    super.key,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  /// The seven days (local midnight) of the week containing [day].
  /// `DateTime.weekday` is 1 for Monday, so the offset is `weekday - 1`.
  static List<DateTime> weekOf(DateTime day) {
    return <DateTime>[
      for (int i = 0; i < 7; i++)
        DateTime(day.year, day.month, day.day - (day.weekday - 1) + i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = weekOf(selectedDay);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final DateTime day in days)
          _WeekDay(
            day: day,
            isSelected: day.year == selectedDay.year &&
                day.month == selectedDay.month &&
                day.day == selectedDay.day,
            onTap: () => onSelected(day),
          ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String semanticsLabel = '${PtDateLabels.weekdayName(day)} ${day.day}'
        '${isSelected ? ', seleccionado' : ''}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 44,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                PtDateLabels.weekdaysShort[day.weekday - 1].toUpperCase(),
                style: AppTypography.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.sm - 1),
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: Text(
                  '${day.day}',
                  style: AppTypography.mono.copyWith(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
