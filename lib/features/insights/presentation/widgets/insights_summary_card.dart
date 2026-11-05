import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../dashboard/domain/dashboard_snapshot.dart';

/// "Resumo geral": the same counters as the Progresso ring card, for
/// the month window.
class InsightsSummaryCard extends StatelessWidget {
  const InsightsSummaryCard({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('RESUMO GERAL', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatBlock(
                  value: snapshot.performance.completedCount,
                  label: 'Concluídas',
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: _StatBlock(
                  value: snapshot.performance.snoozedCount,
                  label: 'Com snooze',
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: _StatBlock(
                  value: snapshot.performance.missedCount +
                      snapshot.performance.declinedCount,
                  label: 'Não cumpridas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md - 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: AppTypography.mono.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
