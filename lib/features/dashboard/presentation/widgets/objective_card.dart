import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../onboarding/application/settings_controller.dart';
import '../../../onboarding/domain/settings.dart';

/// The user's main objective, on the Progresso tab. It follows the
/// objective set in onboarding and edited in the Perfil. (Objectives
/// linked to tasks and routines are post-MVP.)
class ObjectiveCard extends ConsumerWidget {
  const ObjectiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Settings> settingsAsync = ref.watch(
      settingsControllerProvider,
    );

    // Pattern-matching, not `.when()` (see DashboardScreen). While the
    // settings load, or if they fail, the card simply is not shown.
    return switch (settingsAsync) {
      AsyncData<Settings>(:final value) => _card(value.mainObjective.trim()),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _card(String objective) {
    final bool hasObjective = objective.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('OBJETIVO', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasObjective ? objective : 'Ainda sem objetivo definido.',
            style: hasObjective
                ? AppTypography.titleMedium
                : AppTypography.bodyMedium,
          ),
          if (!hasObjective) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Define o teu objetivo no Perfil.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
