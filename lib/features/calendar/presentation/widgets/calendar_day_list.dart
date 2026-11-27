import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/domain/day_window.dart';
import '../../../tasks/domain/occurrence_status.dart';
import '../../../tasks/domain/task_priority.dart';
import '../../domain/calendar_task_item.dart';
import 'task_detail_sheet.dart';

/// The occurrences of the selected day, in the same visual style as
/// the Home's "Hoje" list.
class CalendarDayList extends StatelessWidget {
  const CalendarDayList({
    required this.items,
    this.onTap,
    this.dayWindow,
    super.key,
  });

  final List<CalendarTaskItem> items;

  /// Called when a card is tapped; when null the cards are not tappable.
  final ValueChanged<CalendarTaskItem>? onTap;

  /// The user's day (Perfil). A task outside it is labelled "fora do
  /// teu dia"; null = no marking.
  final DayWindow? dayWindow;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        title: context.l10n.noTasksTitle,
        message: context.l10n.noTasksMessage,
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
            statusLabel: _statusLabel(context.l10n, item),
            tone: _tone(item),
            onTap: onTap == null ? null : () => onTap!(item),
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

  String _statusLabel(AppLocalizations l10n, CalendarTaskItem item) {
    final String status = TaskDetailSheet.statusLabel(l10n, item.status);
    final DayWindow? window = dayWindow;
    if (window != null && !window.containsTime(item.scheduledAt)) {
      return '$status · ${l10n.outsideYourDay}';
    }
    return status;
  }
}
