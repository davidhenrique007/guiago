import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alarm_permission_checker.dart';
import '../infrastructure/permission_handler_alarm_permission_checker.dart';

final Provider<AlarmPermissionChecker> alarmPermissionCheckerProvider =
    Provider<AlarmPermissionChecker>(
  (ref) => const PermissionHandlerAlarmPermissionChecker(),
);

/// Current permission state. `autoDispose` so it is re-read every time
/// a screen that shows it is opened.
final alarmPermissionStatusProvider =
    FutureProvider.autoDispose<AlarmPermissionStatus>((ref) {
  final AlarmPermissionChecker checker =
      ref.watch(alarmPermissionCheckerProvider);
  return checker.check();
});
