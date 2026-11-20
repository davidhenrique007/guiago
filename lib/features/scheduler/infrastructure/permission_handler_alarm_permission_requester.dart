import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

import '../domain/alarm_permission_checker.dart';
import '../domain/alarm_permission_requester.dart';

/// Requests notifications and exact alarms through `permission_handler`.
/// Never throws: any platform error is reported as "not granted" so the
/// caller (task creation) is never blocked by a permission problem.
class PermissionHandlerAlarmPermissionRequester
    implements AlarmPermissionRequester {
  const PermissionHandlerAlarmPermissionRequester();

  @override
  Future<AlarmPermissionStatus> request() async {
    if (!Platform.isAndroid) {
      return const AlarmPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: true,
      );
    }
    try {
      final PermissionStatus notification =
          await Permission.notification.request();
      final PermissionStatus exactAlarm =
          await Permission.scheduleExactAlarm.request();
      return AlarmPermissionStatus(
        notificationsGranted: notification.isGranted,
        exactAlarmsGranted: exactAlarm.isGranted,
      );
    } on Object {
      return const AlarmPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
    }
  }
}
