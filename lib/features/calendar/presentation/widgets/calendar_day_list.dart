import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../tasks/domain/occurrence_status.dart';
import '../../../tasks/domain/task_priority.dart';
import '../../domain/calendar_task_item.dart';

/// The occurrences of the selected day, in the same visual style as
/// the Home's "Hoje" list.
class CalendarDayList extends StatelessWidget {
  const CalendarDayList({required this.items, super.key});

  final List<CalendarTaskItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sem tarefas neste dia',
        message: 'Toca em + para criar uma tarefa.',
        icon: Icons.event_available_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final CalendarTaskItem item in items) ...<Widget>[
          AppTaskCard(
            time: _timeLabel(item.scheduledAt),
            title: item.title,
            statusLabel: _statusLabel(item.status),
            tone: _tone(item),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  static AppTaskCardTone _tone(CalendarTaskItem item) {
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
