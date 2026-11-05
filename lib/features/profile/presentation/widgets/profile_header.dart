import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../onboarding/domain/settings.dart';

/// Initial in a circle, the user's name and their main objective.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.settings, super.key});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final String name = settings.userName.trim();
    final String objective = settings.mainObjective.trim();

    return Row(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name.isEmpty ? 'Sem nome' : name,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                objective.isEmpty ? 'Sem objetivo definido' : objective,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
