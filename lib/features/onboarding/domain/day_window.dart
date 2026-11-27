import 'settings.dart';

/// The user's day, from "Início do dia" to "Fim do dia" (Perfil), in
/// minutes after midnight. It tells the app which hours are "inside"
/// the user's day; nothing is blocked outside it.
class DayWindow {
  const DayWindow({required this.startMinutes, required this.endMinutes});

  factory DayWindow.fromSettings(Settings settings) => DayWindow(
        startMinutes: settings.dayStartMinutes,
        endMinutes: settings.dayEndMinutes,
      );

  final int startMinutes;
  final int endMinutes;

  /// True when [minutesOfDay] is from the start to the end, both inclusive.
  bool contains(int minutesOfDay) =>
      minutesOfDay >= startMinutes && minutesOfDay <= endMinutes;

  bool containsTime(DateTime dateTime) =>
      contains(dateTime.hour * 60 + dateTime.minute);

  /// A time to suggest for a future day: [preferredMinutes] when it is
  /// inside the window, otherwise the closest edge of the window.
  int suggest(int preferredMinutes) {
    if (preferredMinutes < startMinutes) return startMinutes;
    if (preferredMinutes > endMinutes) return endMinutes;
    return preferredMinutes;
  }

  /// "07:30–23:55".
  String get label => '${_hhmm(startMinutes)}–${_hhmm(endMinutes)}';

  static String _hhmm(int minutes) {
    final String h = (minutes ~/ 60).toString().padLeft(2, '0');
    final String m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
