import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../dashboard/domain/dashboard_period.dart';
import '../../../dashboard/domain/dashboard_snapshot.dart';
import '../../application/insights_controller.dart';
import '../../domain/insights_snapshot.dart';
import '../widgets/insights_productivity_card.dart';
import '../widgets/insights_summary_card.dart';
import '../widgets/insights_top_tasks_card.dart';

/// Insights over the last 30 days. The summary reuses the dashboard's
/// month snapshot; the hour and top-task cards come from
/// [InsightsController]. Reached from the Perfil tab.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const DashboardPeriod _period = DashboardPeriod.month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardSnapshot> summaryAsync = ref.watch(
      dashboardControllerProvider(_period),
    );
    final AsyncValue<InsightsSnapshot> insightsAsync = ref.watch(
      insightsControllerProvider,
    );

    void refresh() {
      ref.read(dashboardControllerProvider(_period).notifier).refresh();
      ref.read(insightsControllerProvider.notifier).refresh();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Insights', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            refresh();
            await ref.read(dashboardControllerProvider(_period).future);
            await ref.read(insightsControllerProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Text(
                'Mês · últimos 30 dias',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // Pattern-matching, not `.when()` (see DashboardScreen).
              switch ((summaryAsync, insightsAsync)) {
                (
                  AsyncData<DashboardSnapshot>(value: final summary),
                  AsyncData<InsightsSnapshot>(value: final insights),
                ) =>
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      InsightsSummaryCard(snapshot: summary),
                      const SizedBox(height: AppSpacing.md),
                      InsightsProductivityCard(snapshot: insights),
                      const SizedBox(height: AppSpacing.md),
                      InsightsTopTasksCard(tasks: insights.topTasks),
                    ],
                  ),
                (AsyncError<DashboardSnapshot>(), _) ||
                (_, AsyncError<InsightsSnapshot>()) =>
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar os insights.',
                      onRetry: refresh,
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
