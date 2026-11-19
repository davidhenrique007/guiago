import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

import '../domain/alarm_permission_checker.dart';

/// Reads the real permission state through `permission_handler`.
/// Only Android restricts exact alarms and (since 13) notifications in
/// a way the app must surface; elsewhere it reports "granted".
class PermissionHandlerAlarmPermissionChecker
    implements AlarmPermissionChecker {
  const PermissionHandlerAlarmPermissionChecker();

  @override
  Future<AlarmPermissionStatus> check() async {
    if (!Platform.isAndroid) {
      return const AlarmPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: true,
      );
    }
    final PermissionStatus notification = await Permission.notification.status;
    final PermissionStatus exactAlarm =
        await Permission.scheduleExactAlarm.status;
    return AlarmPermissionStatus(
      notificationsGranted: notification.isGranted,
      exactAlarmsGranted: exactAlarm.isGranted,
    );
  }
}
