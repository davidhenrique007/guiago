import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tasks/domain/occurrence_status.dart';
import '../../../tasks/domain/recurrence_rule.dart';
import '../../../tasks/domain/task_priority.dart';
import '../../data/calendar_providers.dart';
import '../../domain/calendar_task_detail.dart';

/// Read-only details of one occurrence. Editing and removing live in
/// the Tasks tab, so this sheet only points there.
abstract final class TaskDetailSheet {
  static Future<void> show(
    BuildContext context, {
    required String occurrenceId,
    required String title,
  }) {
    return AppBottomSheet.show<void>(
      context,
      title: title,
      child: _DetailBody(occurrenceId: occurrenceId),
    );
  }

  static String statusLabel(AppLocalizations l10n, OccurrenceStatus status) =>
      switch (status) {
        OccurrenceStatus.scheduled => l10n.statusScheduled,
        OccurrenceStatus.triggered => l10n.statusTriggered,
        OccurrenceStatus.snoozed => l10n.statusSnoozed,
        OccurrenceStatus.completed => l10n.statusCompleted,
        OccurrenceStatus.declined => l10n.statusDeclined,
        OccurrenceStatus.missed => l10n.statusMissed,
        OccurrenceStatus.cancelled => l10n.statusCancelled,
      };

  static String priorityLabel(AppLocalizations l10n, TaskPriority priority) =>
      switch (priority) {
        TaskPriority.low => l10n.priorityLow,
        TaskPriority.medium => l10n.priorityMedium,
        TaskPriority.high => l10n.priorityHigh,
      };

  static String recurrenceLabel(AppLocalizations l10n, RecurrenceRule rule) =>
      switch (rule) {
        RecurrenceNone() => l10n.recurrenceNone,
        RecurrenceDaily() => l10n.recurrenceDaily,
        RecurrenceWeekly() => l10n.recurrenceWeekly,
        RecurrenceCustomDays() => l10n.recurrenceCustom,
      };
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.occurrenceId});

  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CalendarTaskDetail> detailAsync = ref.watch(
      calendarTaskDetailProvider(occurrenceId),
    );

    // Pattern-matching, not `.when()` — same convention as the screens.
    return switch (detailAsync) {
      AsyncData<CalendarTaskDetail>(:final value) => _Rows(detail: value),
      AsyncError<CalendarTaskDetail>() => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(context.l10n.detailLoadError),
        ),
      _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: AppLoadingState(),
        ),
    };
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.detail});

  final CalendarTaskDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? description = detail.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (description != null && description.isNotEmpty) ...<Widget>[
          Text(description, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.md),
        ],
        _Row(
          label: l10n.detailWhen,
          value: '${l10n.longDate(detail.scheduledAt)} · '
              '${PtDateLabels.time(detail.scheduledAt)}',
        ),
        _Row(
          label: l10n.detailStatus,
          value: TaskDetailSheet.statusLabel(l10n, detail.status),
        ),
        _Row(
          label: l10n.detailPriority,
          value: TaskDetailSheet.priorityLabel(l10n, detail.priority),
        ),
        _Row(
          label: l10n.detailRepeat,
          value: TaskDetailSheet.recurrenceLabel(l10n, detail.recurrenceRule),
        ),
        _Row(
          label: l10n.detailTolerance,
          value: l10n.minutes(detail.toleranceMinutes),
        ),
        if (detail.snoozeCount > 0)
          _Row(label: l10n.detailSnoozes, value: '${detail.snoozeCount}'),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.detailEditHint,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(label, style: AppTypography.label),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
