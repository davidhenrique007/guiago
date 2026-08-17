import 'package:flutter/animation.dart';

/// GuiaGo motion tokens.
///
/// Per master spec §9: animation communicates change, progress,
/// confirmation, context, or hierarchy — never decoration. Keep
/// durations short and curves consistent across the app.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
}
