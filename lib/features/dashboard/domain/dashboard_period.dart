/// Rolling window shown by the dashboard: today, the last 7 days or
/// the last 30 days (ending today). Rolling windows avoid depending on
/// which weekday the week starts on.
enum DashboardPeriod { today, week, month }

/// Inclusive local-time range covered by a [DashboardPeriod].
typedef DashboardRange = ({DateTime start, DateTime end});

extension DashboardPeriodX on DashboardPeriod {
  int get days => switch (this) {
        DashboardPeriod.today => 1,
        DashboardPeriod.week => 7,
        DashboardPeriod.month => 30,
      };

  /// The range that ends at the last instant of [now]'s local day and
  /// starts at midnight, [days] - 1 days earlier. Uses calendar
  /// arithmetic (not `Duration`) so daylight-saving changes cannot
  /// shift the boundaries.
  DashboardRange rangeAt(DateTime now) {
    final DateTime start = DateTime(now.year, now.month, now.day - (days - 1));
    final DateTime end = DateTime(now.year, now.month, now.day + 1)
        .subtract(const Duration(microseconds: 1));
    return (start: start, end: end);
  }
}
