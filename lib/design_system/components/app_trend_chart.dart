import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Bar chart of one value per day, drawn with [CustomPainter] — no
/// charting dependency. The master spec (§4) doesn't list one, and
/// this project's Riverpod/Freezed versions are recent enough that
/// adding a charting package without verifying compatibility first
/// would risk exactly the kind of breakage already seen in Fase 5.
///
/// Deliberately feature-agnostic: takes plain doubles, not a
/// dashboard-specific type, so design_system/ never has to import a
/// feature.
class AppTrendChart extends StatelessWidget {
  const AppTrendChart({required this.values, this.height = 120, super.key});

  /// One value per bar, oldest first, each normally 0.0–1.0.
  /// A negative value means "no data that day" and draws as a
  /// small empty tick instead of a bar.
  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TrendChartPainter(values: values)),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double barWidth = size.width / values.length;
    final double gap = barWidth * 0.28;
    final Paint filledPaint = Paint()..color = AppColors.primary;
    final Paint emptyPaint = Paint()..color = AppColors.surfaceMuted;

    for (int i = 0; i < values.length; i++) {
      final double value = values[i];
      final bool hasData = value >= 0;
      final double clamped = hasData ? value.clamp(0.0, 1.0) : 0.0;
      final double barHeight =
          hasData ? (size.height * clamped).clamp(4.0, size.height) : 4.0;

      final double left = i * barWidth + gap / 2;
      final double right = (i + 1) * barWidth - gap / 2;
      final double top = size.height - barHeight;

      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, size.height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, hasData ? filledPaint : emptyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
