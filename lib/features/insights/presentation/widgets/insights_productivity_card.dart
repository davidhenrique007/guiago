import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/insights_snapshot.dart';

/// "Melhor horário para produtividade": 24 hourly bars with the peak
/// window highlighted. With too little data it shows an empty state
/// instead of a peak that would be made up.
class InsightsProductivityCard extends StatelessWidget {
  const InsightsProductivityCard({required this.snapshot, super.key});

  final InsightsSnapshot snapshot;

  static String _hour(int hour) =>
      '${(hour % 24).toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final ProductivityPeak? peak = snapshot.peak;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('MELHOR HORÁRIO PARA PRODUTIVIDADE', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          if (peak == null)
            const AppEmptyState(
              title: 'Ainda sem dados suficientes',
              message: 'Conclui mais tarefas para descobrir o teu '
                  'melhor horário.',
              icon: Icons.schedule_outlined,
            )
          else ...<Widget>[
            AppTrendChart(
              height: 60,
              values: _normalised(snapshot.completionsByHour),
              highlightedIndices: <int>{
                for (int h = peak.startHour; h <= peak.endHour; h++) h,
              },
            ),
            const SizedBox(height: AppSpacing.md - 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Pico de produtividade', style: AppTypography.bodyMedium),
                Text(
                  '${_hour(peak.startHour)} – ${_hour(peak.endHour + 1)}',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Scales the hourly counts to 0.0–1.0 against the busiest hour,
  /// which is what the chart draws.
  static List<double> _normalised(List<int> counts) {
    final int max = counts.fold(0, (int m, int c) => c > m ? c : m);
    if (max == 0) return List<double>.filled(counts.length, 0);
    return <double>[for (final int c in counts) c / max];
  }
}
