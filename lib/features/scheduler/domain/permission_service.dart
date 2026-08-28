import '../../../core/result/result.dart';

/// Domain-facing port over OS alarm/notification permissions (master
/// spec §13). Implemented by `PermissionHandlerService` in
/// Infrastructure using `permission_handler`.
abstract interface class PermissionService {
  /// Requests the notification permission if not already granted.
  /// Returns `Success(true)` once granted, `Success(false)` if the
  /// user denies it — a denial is a normal outcome, not a
  /// [Failure]; the caller decides how to react.
  Future<Result<bool>> ensureNotificationPermission();

  /// Requests the exact-alarm permission (Android 12+ only; a no-op
  /// returning `Success(true)` on platforms that don't need it).
  /// Best-effort: [SchedulerEngine] degrades to inexact scheduling
  /// rather than failing outright when this is denied.
  Future<Result<bool>> ensureExactAlarmPermission();
}
