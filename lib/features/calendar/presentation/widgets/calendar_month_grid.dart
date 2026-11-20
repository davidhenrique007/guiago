import 'package:flutter/material.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';

/// A Monday-first month grid. Days that have tasks carry a dot; the
/// selected day is filled. The header has previous/next month buttons.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.selectedDay,
    required this.taskCountByDay,
    required this.onSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    super.key,
  });

  /// Its month is the month shown.
  final DateTime selectedDay;

  /// Keyed by day of month; days without tasks may be absent.
  final Map<int, int> taskCountByDay;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  /// "Novembro 2026".
  static String monthLabel(DateTime day) {
    final String name = PtDateLabels.months[day.month - 1];
    return '${name[0].toUpperCase()}${name.substring(1)} ${day.year}';
  }

  /// Number of days in [day]'s month.
  static int daysInMonth(DateTime day) =>
      DateTime(day.year, day.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(selectedDay.year, selectedDay.month);
    final int total = daysInMonth(first);
    // DateTime.weekday is 1 for Monday, so this many blank cells come
    // before day 1.
    final int leading = first.weekday - 1;
    final int cells = ((leading + total + 6) ~/ 7) * 7;
    final DateTime now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: onPreviousMonth,
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
              ),
            ),
            Text(monthLabel(first), style: AppTypography.titleMedium),
            IconButton(
              tooltip: 'Mês seguinte',
              onPressed: onNextMonth,
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            for (final String short in PtDateLabels.weekdaysShort)
              Expanded(
                child: Center(
                  child: Text(
                    short.substring(0, 1).toUpperCase(),
                    style: AppTypography.label.copyWith(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (int week = 0; week < cells ~/ 7; week++)
          Row(
            children: <Widget>[
              for (int column = 0; column < 7; column++)
                Expanded(
                  child: _cell(
                    dayNumber: week * 7 + column - leading + 1,
                    total: total,
                    first: first,
                    now: now,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell({
    required int dayNumber,
    required int total,
    required DateTime first,
    required DateTime now,
  }) {
    if (dayNumber < 1 || dayNumber > total) {
      return const SizedBox(height: _MonthDay.height);
    }
    final DateTime day = DateTime(first.year, first.month, dayNumber);
    return _MonthDay(
      day: day,
      count: taskCountByDay[dayNumber] ?? 0,
      isSelected: dayNumber == selectedDay.day,
      isToday:
          day.year == now.year && day.month == now.month && day.day == now.day,
      onTap: () => onSelected(day),
    );
  }
}

class _MonthDay extends StatelessWidget {
  const _MonthDay({
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  static const double height = 44;

  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String tasks = switch (count) {
      0 => '',
      1 => ', 1 tarefa',
      _ => ', $count tarefas',
    };
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Dia ${day.day}$tasks${isSelected ? ', seleccionado' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primary)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${day.day}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count == 0
                      ? Colors.transparent
                      : (isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
