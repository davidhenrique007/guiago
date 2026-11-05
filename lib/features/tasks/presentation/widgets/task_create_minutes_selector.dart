import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import 'task_create_selector_chip.dart';

/// A row of "N min" chips (tolerância, snooze padrão).
class TaskCreateMinutesSelector extends StatelessWidget {
  const TaskCreateMinutesSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final int minutes in options)
          SelectorChip(
            label: '$minutes min',
            isSelected: minutes == selected,
            onTap: () => onChanged(minutes),
          ),
      ],
    );
  }
}
