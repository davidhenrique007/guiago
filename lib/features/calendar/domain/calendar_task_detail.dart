import '../../tasks/domain/occurrence_status.dart';
import '../../tasks/domain/recurrence_rule.dart';
import '../../tasks/domain/task_priority.dart';

/// Everything the read-only detail sheet shows about one occurrence.
class CalendarTaskDetail {
  const CalendarTaskDetail({
    required this.title,
    required this.priority,
    required this.recurrenceRule,
    required this.status,
    required this.scheduledAt,
    required this.toleranceMinutes,
    required this.snoozeCount,
    this.description,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final RecurrenceRule recurrenceRule;
  final OccurrenceStatus status;
  final DateTime scheduledAt;
  final int toleranceMinutes;
  final int snoozeCount;
}
