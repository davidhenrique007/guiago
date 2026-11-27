import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// The twelve months of a year, with previous/next year buttons. A
/// month that has tasks shows how many; the current month is outlined.
/// Tapping a month hands it to the caller (the Calendar opens it in the
/// month view). There is no limit on how far ahead the user can go.
class CalendarYearGrid extends StatelessWidget {
  const CalendarYearGrid({
    required this.year,
    required this.taskCountByMonth,
    required this.onMonthSelected,
    required this.onPreviousYear,
    required this.onNextYear,
    super.key,
  });

  final int year;

  /// Keyed by month (1..12); months without tasks may be absent.
  final Map<int, int> taskCountByMonth;

  /// Receives the first day of the tapped month.
  final ValueChanged<DateTime> onMonthSelected;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              tooltip: l10n.previousYear,
              onPressed: onPreviousYear,
              icon: Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
              ),
            ),
            Text('$year', style: AppTypography.titleMedium),
            IconButton(
              tooltip: l10n.nextYear,
              onPressed: onNextYear,
              icon: Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: <Widget>[
            for (int month = 1; month <= 12; month++)
              _MonthTile(
                name: l10n.monthName(month),
                count: taskCountByMonth[month] ?? 0,
                isCurrent: year == now.year && month == now.month,
                onTap: () => onMonthSelected(DateTime(year, month)),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.name,
    required this.count,
    required this.isCurrent,
    required this.onTap,
  });

  final String name;
  final int count;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool hasTasks = count > 0;
    return Semantics(
      button: true,
      label: hasTasks ? '$name, ${l10n.taskCount(count)}' : name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: isCurrent ? AppColors.primary : AppColors.borderSoft,
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(name, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              if (hasTasks)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.taskCount(count),
                      style: AppTypography.label.copyWith(fontSize: 10),
                    ),
                  ],
                )
              else
                Text(
                  '—',
                  style: AppTypography.label.copyWith(fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
