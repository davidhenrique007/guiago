/// How many (non-cancelled) occurrences each month of a year has —
/// what the year view needs to mark the months that have plans.
class CalendarYearSnapshot {
  const CalendarYearSnapshot({
    required this.year,
    required this.taskCountByMonth,
  });

  final int year;

  /// Keyed by month (1..12). Months without tasks are absent.
  final Map<int, int> taskCountByMonth;

  int countFor(int month) => taskCountByMonth[month] ?? 0;
}
