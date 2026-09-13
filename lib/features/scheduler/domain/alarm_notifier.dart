import '../../../core/result/result.dart';

/// The native alarm/notification operations [SchedulerEngine] needs.
/// Implemented by `NotificationService` (Infrastructure) for the real
/// app; fakeable in tests without touching platform channels.
abstract interface class AlarmNotifier {
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  });

  Future<Result<void>> cancel(int id);

  Future<Result<void>> cancelAll();

  /// Emits the occurrence ID whenever the user taps a notification
  /// while the app is already running.
  Stream<String> get onNotificationTapped;

  /// If the app was cold-started by tapping a notification, returns
  /// that notification's occurrence ID payload; otherwise `null`.
  /// Call once, near app startup (see ADR-008).
  Future<String?> checkLaunchPayload();
}
