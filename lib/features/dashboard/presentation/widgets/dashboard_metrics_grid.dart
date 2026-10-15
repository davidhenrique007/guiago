import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../performance/domain/level.dart';
import '../../domain/dashboard_snapshot.dart';

/// The 4 headline numbers (master spec §6/§22): Score, Nível, Streak
/// and Completion Rate. Score, Nível and Streak are all-time — they
/// don't change with the selected period; only Completion Rate does.
class DashboardMetricsGrid extends StatelessWidget {
  const DashboardMetricsGrid({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  static const Map<LevelTier, String> _tierLabels = {
    LevelTier.beginner: 'Iniciante',
    LevelTier.consistent: 'Consistente',
    LevelTier.disciplined: 'Disciplinado',
    LevelTier.elite: 'Elite',
  };

  @override
  Widget build(BuildContext context) {
    final bool hasData = !snapshot.performance.isEmpty;
    final int completionPercent =
        hasData ? (snapshot.performance.completionRate * 100).round() : 0;

    final Color? completionColor = !hasData
        ? null
        : completionPercent >= 70
            ? AppColors.success
            : completionPercent >= 40
                ? AppColors.warning
                : AppColors.error;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: [
        AppMetricCard(
          label: 'Pontuação',
          value: '${snapshot.score.total}',
        ),
        AppMetricCard(
          label: 'Nível',
          value: _tierLabels[snapshot.level?.tier ?? LevelTier.beginner]!,
        ),
        AppMetricCard(
          label: 'Sequência',
          value: '${snapshot.streak?.currentStreak ?? 0} dias',
          detail: 'recorde: ${snapshot.streak?.longestStreak ?? 0}',
        ),
        AppMetricCard(
          label: 'Conclusão',
          value: hasData ? '$completionPercent%' : '—',
          valueColor: completionColor,
        ),
      ],
    );
  }
}
