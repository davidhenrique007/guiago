import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/recurrence_rule.dart';
import 'task_create_selector_chip.dart';

/// Recurrence choice: Nenhuma / Diária / Semanal / Dias específicos
/// (master spec §12). The weekday picker only shows for "Dias
/// específicos", and always keeps at least one day selected.
class TaskCreateRecurrenceSelector extends StatelessWidget {
  const TaskCreateRecurrenceSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final RecurrenceRule selected;
  final ValueChanged<RecurrenceRule> onChanged;

  static const List<String> _weekdayLabels = <String>[
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isCustomDays = selected is RecurrenceCustomDays;
    final Set<int> currentDays = isCustomDays
        ? (selected as RecurrenceCustomDays).weekdays
        : const <int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            SelectorChip(
              label: 'Nenhuma',
              isSelected: selected is RecurrenceNone,
              onTap: () => onChanged(const RecurrenceRule.none()),
            ),
            SelectorChip(
              label: 'Diária',
              isSelected: selected is RecurrenceDaily,
              onTap: () => onChanged(const RecurrenceRule.daily()),
            ),
            SelectorChip(
              label: 'Semanal',
              isSelected: selected is RecurrenceWeekly,
              onTap: () => onChanged(const RecurrenceRule.weekly()),
            ),
            SelectorChip(
              label: 'Dias específicos',
              isSelected: isCustomDays,
              onTap: () => onChanged(
                RecurrenceRule.customDays(
                  weekdays: currentDays.isEmpty
                      ? <int>{DateTime.now().weekday}
                      : currentDays,
                ),
              ),
            ),
          ],
        ),
        if (isCustomDays) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: <Widget>[
              for (int weekday = 1; weekday <= 7; weekday++)
                _DayToggle(
                  label: _weekdayLabels[weekday - 1],
                  isSelected: currentDays.contains(weekday),
                  onTap: () {
                    final Set<int> updated = Set<int>.of(currentDays);
                    if (updated.contains(weekday)) {
                      if (updated.length > 1) updated.remove(weekday);
                    } else {
                      updated.add(weekday);
                    }
                    onChanged(RecurrenceRule.customDays(weekdays: updated));
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
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
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color:
                isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
