import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/dashboard_snapshot.dart';

/// "Streak": current streak and the best one ever. A missing
/// `StreakStatus` (nothing evaluated yet) reads as 0 days.
class ProgressStreakCard extends StatelessWidget {
  const ProgressStreakCard({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final int current = snapshot.streak?.currentStreak ?? 0;
    final int longest = snapshot.streak?.longestStreak ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('STREAK', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(
                Icons.local_fire_department_rounded,
                size: 34,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$current ${current == 1 ? 'dia' : 'dias'}',
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Melhor streak: $longest ${longest == 1 ? 'dia' : 'dias'}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
