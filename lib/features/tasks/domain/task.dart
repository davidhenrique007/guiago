import 'package:freezed_annotation/freezed_annotation.dart';

import 'recurrence_rule.dart';
import 'task_priority.dart';

part 'task.freezed.dart';

/// A task the user wants to be reminded to act on (master spec §10,
/// §17). Pure Domain type — no Flutter, no Drift.
///
/// A [Task] only describes *what* and *how it repeats*; the actual
/// scheduled instances are [TaskOccurrence]s, generated one at a
/// time by the Recurrence Engine as each prior occurrence resolves
/// (master spec §12 — never generated infinitely up front).
@freezed
sealed class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    required TaskPriority priority,
    required RecurrenceRule recurrenceRule,
    required int defaultToleranceMinutes,
    required int defaultSnoozeMinutes,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isArchived,
  }) = _Task;

  const Task._();
}
