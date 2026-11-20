/// How many (non-cancelled) occurrences each day of a month has —
/// what the month grid needs to mark days that have tasks.
class CalendarMonthSnapshot {
  const CalendarMonthSnapshot({
    required this.month,
    required this.taskCountByDay,
  });

  /// First day of the month, at local midnight.
  final DateTime month;

  /// Keyed by day of month (1..31). Days without tasks are absent.
  final Map<int, int> taskCountByDay;

  int countFor(int dayOfMonth) => taskCountByDay[dayOfMonth] ?? 0;
}
