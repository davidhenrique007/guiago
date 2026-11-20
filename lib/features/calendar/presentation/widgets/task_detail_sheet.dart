import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
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

  static String statusLabel(OccurrenceStatus status) => switch (status) {
        OccurrenceStatus.scheduled => 'Agendada',
        OccurrenceStatus.triggered => 'Em curso',
        OccurrenceStatus.snoozed => 'Adiada',
        OccurrenceStatus.completed => 'Concluída',
        OccurrenceStatus.declined => 'Recusada',
        OccurrenceStatus.missed => 'Perdida',
        OccurrenceStatus.cancelled => 'Cancelada',
      };

  static String priorityLabel(TaskPriority priority) => switch (priority) {
        TaskPriority.low => 'Baixa',
        TaskPriority.medium => 'Média',
        TaskPriority.high => 'Alta',
      };

  static String recurrenceLabel(RecurrenceRule rule) => switch (rule) {
        RecurrenceNone() => 'Nenhuma',
        RecurrenceDaily() => 'Diária',
        RecurrenceWeekly() => 'Semanal',
        RecurrenceCustomDays() => 'Dias específicos',
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
      AsyncError<CalendarTaskDetail>() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text('Não foi possível carregar a tarefa.'),
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
          label: 'Quando',
          value: '${PtDateLabels.longDate(detail.scheduledAt)} · '
              '${PtDateLabels.time(detail.scheduledAt)}',
        ),
        _Row(
          label: 'Estado',
          value: TaskDetailSheet.statusLabel(detail.status),
        ),
        _Row(
          label: 'Prioridade',
          value: TaskDetailSheet.priorityLabel(detail.priority),
        ),
        _Row(
          label: 'Repetição',
          value: TaskDetailSheet.recurrenceLabel(detail.recurrenceRule),
        ),
        _Row(label: 'Tolerância', value: '${detail.toleranceMinutes} min'),
        if (detail.snoozeCount > 0)
          _Row(label: 'Adiamentos', value: '${detail.snoozeCount}'),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Para editar ou apagar, usa a aba Tarefas.',
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
