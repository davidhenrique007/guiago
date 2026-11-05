import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../performance/domain/level.dart';
import '../../../performance/presentation/level_tier_label.dart';
import '../../domain/dashboard_snapshot.dart';

/// "Nível atual": tier name, a bar towards the next tier and the
/// "Faltam X pontos" line. The bar and the line only appear when the
/// snapshot carries a next tier (see `NextLevelProgress`).
class ProgressLevelCard extends StatelessWidget {
  const ProgressLevelCard({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final LevelTier tier = snapshot.level?.tier ?? LevelTier.beginner;
    final LevelTier? next = snapshot.nextTier;
    final int? points = snapshot.pointsToNextTier;
    final double? progress = snapshot.nextTierProgress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('NÍVEL ATUAL', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(
                Icons.workspace_premium_outlined,
                size: 24,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(tier.label, style: AppTypography.titleMedium),
              const Spacer(),
              Text(
                '${snapshot.score.total} pts',
                style: AppTypography.mono.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (next != null && points != null && progress != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppProgress(value: progress),
            const SizedBox(height: AppSpacing.sm + 1),
            Text(
              'Faltam $points ${points == 1 ? 'ponto' : 'pontos'} '
              'para ${next.label}',
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
