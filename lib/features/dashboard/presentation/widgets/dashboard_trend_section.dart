import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/dashboard_period.dart';
import '../../domain/dashboard_snapshot.dart';

/// Trend chart card: the daily completion-rate bars plus a caption
/// naming the period.
class DashboardTrendSection extends StatelessWidget {
  const DashboardTrendSection({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  static const Map<DashboardPeriod, String> _captions = {
    DashboardPeriod.today: 'Hoje',
    DashboardPeriod.week: 'Últimos 7 dias',
    DashboardPeriod.month: 'Últimos 30 dias',
  };

  @override
  Widget build(BuildContext context) {
    final List<double> values = snapshot.trend
        .map((point) => point.hasData ? point.completionRate : -1.0)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendência', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(_captions[snapshot.period]!, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          AppTrendChart(values: values),
        ],
      ),
    );
  }
}
