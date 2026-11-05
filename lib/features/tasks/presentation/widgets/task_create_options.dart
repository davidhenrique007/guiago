/// The choices offered for tolerance and snooze when creating a task.
/// Kept in one place, like the other policies, instead of scattered
/// through the widgets.
abstract final class TaskCreateOptions {
  static const List<int> toleranceMinutes = <int>[5, 10, 15, 30, 60];
  static const List<int> snoozeMinutes = <int>[5, 10, 15, 30];

  /// [options] plus [current] when it is not already there (a default
  /// saved in onboarding may be outside the standard list), sorted.
  static List<int> including(List<int> options, int current) {
    if (options.contains(current)) return options;
    return <int>[...options, current]..sort();
  }
}
