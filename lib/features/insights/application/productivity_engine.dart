import '../../tasks/domain/task_occurrence.dart';
import '../domain/insights_policy.dart';
import '../domain/insights_snapshot.dart';

/// Pure: turns completed occurrences into an hour-of-day histogram
/// and the most productive window.
class ProductivityEngine {
  const ProductivityEngine({this.policy = InsightsPolicy.defaultPolicy});

  final InsightsPolicy policy;

  /// Completions per local hour (24 entries). The hour is that of
  /// `completedAt`, falling back to `scheduledAt` only as a safeguard
  /// (the TaskEngine always sets `completedAt` on completion).
  List<int> histogram(List<TaskOccurrence> completed) {
    final List<int> counts = List<int>.filled(24, 0);
    for (final TaskOccurrence occurrence in completed) {
      final int hour =
          (occurrence.completedAt ?? occurrence.scheduledAt).toLocal().hour;
      counts[hour]++;
    }
    return counts;
  }

  /// The [InsightsPolicy.peakWindowHours] consecutive hours with the
  /// most completions; a tie goes to the earliest window. Windows do
  /// not wrap past midnight. Null when there are fewer than
  /// [InsightsPolicy.minCompletions] completions.
  ProductivityPeak? peak(List<int> histogram) {
    final int total = histogram.fold(0, (int sum, int c) => sum + c);
    if (total < policy.minCompletions) return null;

    final int window = policy.peakWindowHours;
    int bestStart = 0;
    int bestSum = -1;
    for (int start = 0; start + window <= histogram.length; start++) {
      int sum = 0;
      for (int h = start; h < start + window; h++) {
        sum += histogram[h];
      }
      if (sum > bestSum) {
        bestSum = sum;
        bestStart = start;
      }
    }
    return ProductivityPeak(
      startHour: bestStart,
      endHour: bestStart + window - 1,
    );
  }
}
