import 'package:flutter/foundation.dart';
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
  const AppTrendChart({
    required this.values,
    this.height = 120,
    this.highlightedIndices = const <int>{},
    this.dimColor = AppColors.border,
    super.key,
  });

  /// One value per bar, oldest first, each normally 0.0–1.0.
  /// A negative value means "no data that day" and draws as a
  /// small empty tick instead of a bar.
  final List<double> values;
  final double height;

  /// Bars drawn in the primary color while every other bar uses
  /// [dimColor]. Empty (the default) draws all bars in the primary
  /// color, as before.
  final Set<int> highlightedIndices;
  final Color dimColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendChartPainter(
          values: values,
          highlightedIndices: highlightedIndices,
          dimColor: dimColor,
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.values,
    required this.highlightedIndices,
    required this.dimColor,
  });

  final List<double> values;
  final Set<int> highlightedIndices;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double barWidth = size.width / values.length;
    final double gap = barWidth * 0.28;
    final Paint filledPaint = Paint()..color = AppColors.primary;
    final Paint dimPaint = Paint()..color = dimColor;
    final bool hasHighlight = highlightedIndices.isNotEmpty;
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
      final Paint paint = !hasData
          ? emptyPaint
          : (!hasHighlight || highlightedIndices.contains(i))
              ? filledPaint
              : dimPaint;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return !listEquals(oldDelegate.values, values) ||
        !setEquals(oldDelegate.highlightedIndices, highlightedIndices) ||
        oldDelegate.dimColor != dimColor;
  }
}
