import 'package:flutter/material.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
import '../../application/tasks_view_state.dart';
import '../../domain/occurrence_status.dart';
import '../../domain/task_priority.dart';

/// A plain list of [TaskListItem]s rendered with [AppTaskCard].
class TasksListSection extends StatelessWidget {
  const TasksListSection({required this.items, this.onTap, super.key});

  final List<TaskListItem> items;

  /// Called when a card is tapped; when null the cards are not tappable.
  final ValueChanged<TaskListItem>? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final TaskListItem item in items) ...<Widget>[
          AppTaskCard(
            time: PtDateLabels.time(item.scheduledAt),
            title: item.title,
            statusLabel: _statusLabel(item),
            tone: _tone(item),
            onTap: onTap == null ? null : () => onTap!(item),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  static AppTaskCardTone _tone(TaskListItem item) {
    if (item.status == OccurrenceStatus.completed) return AppTaskCardTone.done;
    return switch (item.priority) {
      TaskPriority.high => AppTaskCardTone.high,
      TaskPriority.medium => AppTaskCardTone.medium,
      TaskPriority.low => AppTaskCardTone.low,
    };
  }

  /// "Agendada · 21/11" — the card's time column is only wide enough
  /// for HH:mm, so the date travels in the status line.
  static String _statusLabel(TaskListItem item) {
    final String day = item.scheduledAt.day.toString().padLeft(2, '0');
    final String month = item.scheduledAt.month.toString().padLeft(2, '0');
    final String base = switch (item.status) {
      OccurrenceStatus.scheduled => 'Agendada',
      OccurrenceStatus.triggered => 'Em curso',
      OccurrenceStatus.snoozed => 'Adiada',
      OccurrenceStatus.completed => 'Concluída',
      OccurrenceStatus.declined => 'Recusada',
      OccurrenceStatus.missed => 'Perdida',
      OccurrenceStatus.cancelled => 'Cancelada',
    };
    return '$base · $day/$month';
  }
}
