/// The two ways the Calendar tab can show time. The selected day's
/// list is below both: it is the "day" view.
enum CalendarViewMode {
  week('Semana'),
  month('Mês');

  const CalendarViewMode(this.label);

  final String label;
}
