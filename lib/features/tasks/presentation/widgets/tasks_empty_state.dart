import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import 'tasks_segment_bar.dart';

/// Empty state of one Tasks segment. When the user has no task at all
/// (a brand-new app) the "Hoje" segment invites them to create the
/// first one — this tab is the only place where tasks are created.
class TasksEmptyState extends StatelessWidget {
  const TasksEmptyState({
    required this.segment,
    required this.hasAnyTask,
    required this.onCreate,
    super.key,
  });

  final TasksSegment segment;

  /// True when at least one list has content, i.e. the user is not new.
  final bool hasAnyTask;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyTask) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppEmptyState(
            title: 'Ainda sem tarefas',
            message:
                'Cria a tua primeira tarefa para começares a organizar o teu dia.',
            icon: Icons.checklist_rtl_outlined,
          ),
          SizedBox(
            width: 260,
            child: AppButton(label: 'Nova tarefa', onPressed: onCreate),
          ),
        ],
      );
    }
    return switch (segment) {
      TasksSegment.today => const AppEmptyState(
          title: 'Sem tarefas para hoje',
          message: 'Tudo em dia. Aproveita o resto do dia.',
          icon: Icons.event_available_outlined,
        ),
      TasksSegment.upcoming => const AppEmptyState(
          title: 'Sem tarefas próximas',
          message: 'As tarefas dos próximos dias aparecem aqui.',
          icon: Icons.upcoming_outlined,
        ),
      TasksSegment.completed => const AppEmptyState(
          title: 'Nada concluído ainda',
          message: 'As tarefas que resolveres aparecem aqui.',
          icon: Icons.task_alt_outlined,
        ),
    };
  }
}
