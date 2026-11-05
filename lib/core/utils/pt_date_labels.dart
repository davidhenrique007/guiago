/// Portuguese weekday and month names, shared by every screen that
/// prints a date (Home, Calendário). Plain constants instead of
/// `intl`, which the project does not depend on.
abstract final class PtDateLabels {
  /// Indexed by `DateTime.weekday - 1` (Monday first).
  static const List<String> weekdays = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  /// Three-letter weekday abbreviations, Monday first.
  static const List<String> weekdaysShort = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  /// Indexed by `DateTime.month - 1`.
  static const List<String> months = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Full weekday name, capitalised: "Quinta-feira".
  static String weekdayName(DateTime date) =>
      _capitalize(weekdays[date.weekday - 1]);

  /// "Quinta-feira, 14 de agosto" (month in lower case).
  static String longDate(DateTime date) =>
      '${weekdayName(date)}, ${date.day} de ${months[date.month - 1]}';

  /// "08:05" (24-hour, zero-padded).
  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  /// "14 DE AGOSTO" — the upper-case date used on the alarm screen.
  static String dayAndMonthUpper(DateTime date) =>
      '${date.day} DE ${months[date.month - 1].toUpperCase()}';

  static String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}
