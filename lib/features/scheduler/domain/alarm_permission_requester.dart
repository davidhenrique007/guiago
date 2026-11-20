import 'alarm_permission_checker.dart';

/// Asks the OS for the permissions GuiaGo's alarms need and reports the
/// resulting state. Kept apart from [AlarmPermissionChecker] (read-only)
/// and from `AlarmNotifier` so existing fakes keep working.
abstract interface class AlarmPermissionRequester {
  Future<AlarmPermissionStatus> request();
}
