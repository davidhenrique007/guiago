import '../domain/alarm_notifier.dart';

/// Makes a change of alarm preferences take effect on the alarms that
/// are already scheduled (they were armed with the old channel):
/// - notifications off: every pending alarm is cancelled;
/// - anything else: the live occurrences are re-armed with the
///   current preferences.
class AlarmPreferencesApplier {
  AlarmPreferencesApplier({
    required AlarmNotifier notifier,
    required Future<void> Function() rearm,
  })  : _notifier = notifier,
        _rearm = rearm;

  final AlarmNotifier _notifier;
  final Future<void> Function() _rearm;

  /// Never throws: failing to re-arm must not break saving a setting
  /// (the recovery that runs on every app start retries it).
  Future<void> apply({required bool notificationsEnabled}) async {
    try {
      if (notificationsEnabled) {
        await _rearm();
      } else {
        await _notifier.cancelAll();
      }
    } on Object {
      return;
    }
  }
}
