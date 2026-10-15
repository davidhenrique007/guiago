import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_period.dart';
import '../../domain/dashboard_snapshot.dart';
import '../widgets/dashboard_metrics_grid.dart';
import '../widgets/dashboard_period_selector.dart';
import '../widgets/dashboard_trend_section.dart';

/// The Dashboard (master spec §6/§22): Score, Nível, Streak and
/// Completion Rate for a rolling Hoje/Semana/Mês window, plus a
/// trend chart. Purely a view over what [DashboardController] loads
/// — this screen never computes a metric itself (§6: "a UI não deve
/// calcular métricas").
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardPeriod _period = DashboardPeriod.today;

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
        title: Text('Desempenho', style: AppTypography.titleLarge),
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
              // removed in Riverpod 3.0; see its comment on
              // `_currentState`).
              switch (snapshotAsync) {
                AsyncData<DashboardSnapshot>(:final value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DashboardMetricsGrid(snapshot: value),
                      const SizedBox(height: AppSpacing.lg),
                      DashboardTrendSection(snapshot: value),
                    ],
                  ),
                AsyncError<DashboardSnapshot>() => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                    ),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o desempenho.',
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
