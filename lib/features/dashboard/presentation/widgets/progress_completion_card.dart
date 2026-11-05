import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/dashboard_snapshot.dart';

/// "Taxa de cumprimento": a ring with the completion percentage and
/// the three counters next to it. Every number comes from
/// `snapshot.performance` — nothing is computed here, except the
/// rounding for display.
class ProgressCompletionCard extends StatelessWidget {
  const ProgressCompletionCard({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bool hasData = !snapshot.performance.isEmpty;
    final double rate = hasData ? snapshot.performance.completionRate : 0;
    final int notFulfilled =
        snapshot.performance.missedCount + snapshot.performance.declinedCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('TAXA DE CUMPRIMENTO', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Semantics(
                label: hasData
                    ? 'Taxa de cumprimento ${(rate * 100).round()} por cento'
                    : 'Taxa de cumprimento sem dados',
                excludeSemantics: true,
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: _RingPainter(value: rate),
                    child: Center(
                      child: Text(
                        hasData ? '${(rate * 100).round()}%' : '—',
                        style: AppTypography.mono.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg - 4),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _LegendRow(
                      color: AppColors.primary,
                      label: 'Concluídas',
                      value: snapshot.performance.completedCount,
                    ),
                    const SizedBox(height: AppSpacing.sm + 1),
                    _LegendRow(
                      color: AppColors.accent,
                      label: 'Com snooze',
                      value: snapshot.performance.snoozedCount,
                    ),
                    const SizedBox(height: AppSpacing.sm + 1),
                    _LegendRow(
                      color: AppColors.error,
                      label: 'Não cumpridas',
                      value: notFulfilled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(
          '$value',
          style: AppTypography.mono.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value});

  /// 0.0–1.0
  final double value;

  static const double _stroke = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(_stroke / 2);

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = AppColors.border;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, track);

    if (value <= 0) return;
    final Paint fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}
