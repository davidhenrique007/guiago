import 'package:permission_handler/permission_handler.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/permission_service.dart';

/// [PermissionService] backed by `permission_handler` (master spec
/// §13, §30).
class PermissionHandlerService implements PermissionService {
  @override
  Future<Result<bool>> ensureNotificationPermission() async {
    try {
      PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      return Success<bool>(status.isGranted);
    } catch (e) {
      return Fail<bool>(
        PermissionFailure(
          'Failed to check/request notification permission',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> ensureExactAlarmPermission() async {
    try {
      // Only meaningful on Android 12+ (API 31+); permission_handler
      // reports this as already-granted on platforms where the
      // concept doesn't apply, so no platform branching is needed
      // here.
      PermissionStatus status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        status = await Permission.scheduleExactAlarm.request();
      }
      return Success<bool>(status.isGranted);
    } catch (e) {
      return Fail<bool>(
        PermissionFailure(
          'Failed to check/request exact-alarm permission',
          cause: e,
        ),
      );
    }
  }
}
