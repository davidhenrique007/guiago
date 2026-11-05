import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/insights_snapshot.dart';

/// "Tarefas mais concluídas": top tasks with a bar proportional to the
/// most completed one.
class InsightsTopTasksCard extends StatelessWidget {
  const InsightsTopTasksCard({required this.tasks, super.key});

  final List<TopTaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final int max = tasks.isEmpty ? 1 : tasks.first.completedCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('TAREFAS MAIS CONCLUÍDAS', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            const AppEmptyState(
              title: 'Ainda sem tarefas concluídas',
              icon: Icons.task_alt_outlined,
            )
          else
            for (int i = 0; i < tasks.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      tasks[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${tasks[i].completedCount}',
                    style: AppTypography.mono.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm - 1),
              AppProgress(value: tasks[i].completedCount / max),
            ],
        ],
      ),
    );
  }
}
