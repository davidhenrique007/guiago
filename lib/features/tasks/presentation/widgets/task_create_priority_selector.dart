import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/task_priority.dart';
import 'task_create_selector_chip.dart';

/// Priority chips, built from [TaskPriority.values]; the exhaustive
/// switch in `_label` makes the compiler flag a new priority.
class TaskCreatePrioritySelector extends StatelessWidget {
  const TaskCreatePrioritySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  static String _label(TaskPriority priority) => switch (priority) {
        TaskPriority.low => 'Baixa',
        TaskPriority.medium => 'Média',
        TaskPriority.high => 'Alta',
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final TaskPriority priority in TaskPriority.values)
          SelectorChip(
            label: _label(priority),
            isSelected: priority == selected,
            onTap: () => onChanged(priority),
          ),
      ],
    );
  }
}
