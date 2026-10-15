import 'package:freezed_annotation/freezed_annotation.dart';

part 'trend_point.freezed.dart';

/// One day of the dashboard trend chart: how many occurrences ended
/// that day and how many of them were completed.
@freezed
sealed class TrendPoint with _$TrendPoint {
  const factory TrendPoint({
    /// Local date, normalized to midnight.
    required DateTime day,
    required int total,
    required int completed,
  }) = _TrendPoint;

  const TrendPoint._();

  bool get hasData => total > 0;

  /// 0.0 when there was nothing to complete that day.
  double get completionRate => total == 0 ? 0 : completed / total;
}
