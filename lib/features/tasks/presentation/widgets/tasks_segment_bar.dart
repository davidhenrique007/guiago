import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import 'task_create_selector_chip.dart';

/// The three lists of the Tasks tab.
enum TasksSegment {
  today('Hoje'),
  upcoming('Próximas'),
  completed('Concluídas');

  const TasksSegment(this.label);

  final String label;
}

/// Pill selector for [TasksSegment], reusing the shared [SelectorChip]
/// look (same as the Dashboard period selector).
class TasksSegmentBar extends StatelessWidget {
  const TasksSegmentBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final TasksSegment selected;
  final ValueChanged<TasksSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final TasksSegment segment in TasksSegment.values)
          SelectorChip(
            label: segment.label,
            isSelected: segment == selected,
            onTap: () => onSelected(segment),
          ),
      ],
    );
  }
}
