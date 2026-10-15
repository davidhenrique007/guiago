import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/home_snapshot.dart';

/// Today's progress bar + "X de Y concluídas" caption.
class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({required this.snapshot, super.key});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Progresso de hoje', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppProgress(value: snapshot.progress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            snapshot.hasTasksToday
                ? '${snapshot.completedCount} de ${snapshot.totalCount} concluídas'
                : 'Nada agendado para hoje.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
