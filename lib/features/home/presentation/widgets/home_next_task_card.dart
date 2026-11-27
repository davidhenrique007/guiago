import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/today_task_item.dart';
import 'home_task_action_buttons.dart';

/// The single most important thing to do next (master spec §22).
class HomeNextTaskCard extends StatelessWidget {
  const HomeNextTaskCard({
    required this.nextTask,
    this.onComplete,
    this.onSnooze,
    super.key,
  });

  final TodayTaskItem? nextTask;

  /// Quick actions; when null the card shows no buttons.
  final ValueChanged<String>? onComplete;
  final ValueChanged<String>? onSnooze;

  @override
  Widget build(BuildContext context) {
    final TodayTaskItem? task = nextTask;

    if (task == null) {
      return AppCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Tudo em dia por agora.',
                style: AppTypography.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Próxima', style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                Text(task.title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _timeLabel(task.scheduledAt),
                  style: AppTypography.bodyMedium,
                ),
                if (onComplete != null && onSnooze != null)
                  HomeTaskActionButtons(
                    canSnooze: !task.scheduledAt.isAfter(DateTime.now()),
                    onComplete: () => onComplete!(task.occurrenceId),
                    onSnooze: () => onSnooze!(task.occurrenceId),
                  ),
              ],
            ),
          ),
          AppBadge(label: task.priority.name),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime dateTime) {
    final String h = dateTime.hour.toString().padLeft(2, '0');
    final String m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
