import '../../performance/domain/occurrence_outcome.dart';
import '../domain/trend_point.dart';

/// Pure: turns finished occurrences, grouped by local day, into one
/// [TrendPoint] per day of the range (days without occurrences get a
/// zeroed point, so the chart never has holes).
class TrendEngine {
  const TrendEngine();

  /// [outcomesByDay] keys must be local dates normalized to midnight.
  List<TrendPoint> calculate({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Map<DateTime, List<OccurrenceOutcome>> outcomesByDay,
  }) {
    final List<TrendPoint> points = <TrendPoint>[];
    final DateTime last = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    for (var day = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final List<OccurrenceOutcome> outcomes =
          outcomesByDay[day] ?? const <OccurrenceOutcome>[];
      points.add(
        TrendPoint(
          day: day,
          total: outcomes.length,
          completed:
              outcomes.where((o) => o.status == OutcomeStatus.completed).length,
        ),
      );
    }
    return points;
  }
}
