import '../../../core/result/result.dart';

/// Domain-facing port over the native OS alarm/notification
/// mechanism (master spec §13: "O Scheduler deverá comunicar-se com
/// os mecanismos nativos da plataforma").
///
/// [SchedulerEngine] depends on this interface only — never on
/// `flutter_local_notifications` directly. The concrete
/// implementation (`NotificationAlarmScheduler`) lives in
/// Infrastructure, keeping Domain/Application free of platform
/// plugins (master spec §5's layering rule).
abstract interface class AlarmScheduler {
  /// One-time setup (platform init settings, notification channel,
  /// timezone database). Implementations must be idempotent — safe
  /// to call before every operation.
  Future<Result<void>> initialize();

  /// Arms a native alarm/notification for [scheduledAt] (device-local
  /// wall-clock time — see `TimezoneService`). [nativeAlarmId] must
  /// be unique among currently-armed alarms; [payload] carries the
  /// occurrence id so a later phase can route a tap back to it.
  Future<Result<void>> scheduleAlarm({
    required int nativeAlarmId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String payload,
  });

  /// Disarms a previously-scheduled alarm. Safe to call even if
  /// [nativeAlarmId] was never scheduled or already fired.
  Future<Result<void>> cancelAlarm(int nativeAlarmId);

  /// Disarms every alarm this app has scheduled.
  Future<Result<void>> cancelAll();
}
