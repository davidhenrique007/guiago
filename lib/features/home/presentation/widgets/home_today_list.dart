import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../tasks/domain/occurrence_status.dart';
import '../../domain/today_task_item.dart';

/// Today's full list of occurrences (master spec §22).
class HomeTodayList extends StatelessWidget {
  const HomeTodayList({required this.items, super.key});

  final List<TodayTaskItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sem tarefas para hoje',
        message: 'Cria uma tarefa para começares a organizar o teu dia.',
        icon: Icons.event_available_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final TodayTaskItem item in items) ...<Widget>[
          _TodayTaskTile(item: item),
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
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: AppTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  _timeLabel(item.scheduledAt),
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          AppBadge(
            label: _statusLabel(item.status),
            tone: _statusTone(item.status),
          ),
        ],
      ),
    );
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

  static AppBadgeTone _statusTone(OccurrenceStatus status) => switch (status) {
        OccurrenceStatus.completed => AppBadgeTone.success,
        OccurrenceStatus.missed => AppBadgeTone.error,
        OccurrenceStatus.declined => AppBadgeTone.error,
        _ => AppBadgeTone.neutral,
      };
}
