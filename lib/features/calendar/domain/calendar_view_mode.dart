/// The three ways the Calendar tab can show time. "Day" keeps the week
/// strip of the first version above the selected day's list.
enum CalendarViewMode {
  day('Dia'),
  month('Mês'),
  year('Ano');

  const CalendarViewMode(this.label);

  final String label;
}
