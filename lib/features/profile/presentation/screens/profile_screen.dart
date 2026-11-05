import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../onboarding/application/settings_controller.dart';
import '../../../onboarding/domain/settings.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_preferences_card.dart';

/// The Perfil tab: who the user is, the link to Insights and the
/// preferences chosen in onboarding (read-only for now — a screen to
/// edit them is not part of this roadmap).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Settings> settingsAsync = ref.watch(
      settingsControllerProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Perfil', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(settingsControllerProvider.notifier).refresh();
            await ref.read(settingsControllerProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              // Pattern-matching, not `.when()` (see HomeScreen).
              switch (settingsAsync) {
                AsyncData<Settings>(:final value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ProfileHeader(settings: value),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        onTap: () =>
                            context.pushNamed(AppRoutes.profileInsightsName),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.insights_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Insights',
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'O teu melhor horário e as tarefas '
                                    'que mais concluis.',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ProfilePreferencesCard(settings: value),
                    ],
                  ),
                AsyncError<Settings>() => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o perfil.',
                      onRetry: () =>
                          ref.read(settingsControllerProvider.notifier).refresh(),
                    ),
                  ),
                _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppLoadingState(),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
