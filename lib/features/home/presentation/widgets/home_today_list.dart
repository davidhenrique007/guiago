import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../tasks/domain/occurrence_status.dart';
import '../../../tasks/domain/task_priority.dart';
import '../../domain/today_task_item.dart';
import 'home_task_action_buttons.dart';

/// Today's full list of occurrences (master spec §22).
class HomeTodayList extends StatelessWidget {
  const HomeTodayList({
    required this.items,
    this.onComplete,
    this.onSnooze,
    super.key,
  });

  final List<TodayTaskItem> items;

  /// Quick actions; when null the list shows no buttons.
  final ValueChanged<String>? onComplete;
  final ValueChanged<String>? onSnooze;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sem tarefas para hoje',
        message:
            'Cria uma tarefa na aba Tarefas para começares a organizar o teu dia.',
        icon: Icons.event_available_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final TodayTaskItem item in items) ...<Widget>[
          _TodayTaskTile(item: item),
          if (onComplete != null && onSnooze != null && !item.isResolved)
            HomeTaskActionButtons(
              canSnooze: !item.scheduledAt.isAfter(DateTime.now()),
              onComplete: () => onComplete!(item.occurrenceId),
              onSnooze: () => onSnooze!(item.occurrenceId),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TodayTaskTile extends StatelessWidget {
  const _TodayTaskTile({required this.item});

  final TodayTaskItem item;

  @override
  Widget build(BuildContext context) {
    return AppTaskCard(
      time: _timeLabel(item.scheduledAt),
      title: item.title,
      statusLabel: _statusLabel(item.status),
      tone: _tone(item),
    );
  }

  static AppTaskCardTone _tone(TodayTaskItem item) {
    if (item.status == OccurrenceStatus.completed) return AppTaskCardTone.done;
    return switch (item.priority) {
      TaskPriority.high => AppTaskCardTone.high,
      TaskPriority.medium => AppTaskCardTone.medium,
      TaskPriority.low => AppTaskCardTone.low,
    };
  }

  static String _timeLabel(DateTime dateTime) {
    final String h = dateTime.hour.toString().padLeft(2, '0');
    final String m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _statusLabel(OccurrenceStatus status) => switch (status) {
        OccurrenceStatus.scheduled => 'Agendada',
        OccurrenceStatus.triggered => 'Em curso',
        OccurrenceStatus.snoozed => 'Adiada',
        OccurrenceStatus.completed => 'Concluída',
        OccurrenceStatus.declined => 'Recusada',
        OccurrenceStatus.missed => 'Perdida',
        OccurrenceStatus.cancelled => 'Cancelada',
      };
}
