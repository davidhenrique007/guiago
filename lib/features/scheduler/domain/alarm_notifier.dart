import '../../../core/result/result.dart';

/// The native alarm/notification operations [SchedulerEngine] needs.
/// Implemented by `NotificationService` (Infrastructure) in the real
/// app; fakeable in tests without touching platform channels.
abstract interface class AlarmNotifier {
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  });

  Future<Result<void>> cancel(int id);

  Future<Result<void>> cancelAll();
}
