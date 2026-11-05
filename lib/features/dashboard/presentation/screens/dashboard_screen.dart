import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_period.dart';
import '../../domain/dashboard_snapshot.dart';
import '../widgets/dashboard_period_selector.dart';
import '../widgets/dashboard_trend_section.dart';
import '../widgets/progress_completion_card.dart';
import '../widgets/progress_level_card.dart';
import '../widgets/progress_streak_card.dart';

/// "Meu progresso" (the Progresso tab): completion rate, streak,
/// level and a trend chart for a rolling Hoje/Semana/Mês window.
/// Purely a view over what [DashboardController] loads — this screen
/// never computes a metric itself (master spec §6: "a UI não deve
/// calcular métricas").
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardPeriod _period = DashboardPeriod.week;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DashboardSnapshot> snapshotAsync = ref.watch(
      dashboardControllerProvider(_period),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Meu progresso', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(dashboardControllerProvider(_period).notifier).refresh();
            await ref.read(dashboardControllerProvider(_period).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              DashboardPeriodSelector(
                selected: _period,
                onChanged: (DashboardPeriod period) {
                  setState(() => _period = period);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Pattern-matching, not `.when()` — same convention as
              // AlarmRingController (AsyncValue.valueOrNull was
              // removed in Riverpod 3.0).
              switch (snapshotAsync) {
                AsyncData<DashboardSnapshot>(:final value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ProgressCompletionCard(snapshot: value),
                      const SizedBox(height: AppSpacing.md),
                      ProgressStreakCard(snapshot: value),
                      const SizedBox(height: AppSpacing.md),
                      ProgressLevelCard(snapshot: value),
                      const SizedBox(height: AppSpacing.md),
                      DashboardTrendSection(snapshot: value),
                    ],
                  ),
                AsyncError<DashboardSnapshot>() => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                    ),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o progresso.',
                      onRetry: () => ref
                          .read(dashboardControllerProvider(_period).notifier)
                          .refresh(),
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
