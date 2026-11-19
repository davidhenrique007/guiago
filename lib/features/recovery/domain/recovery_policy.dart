/// Every recovery number lives here — never scattered through the code
/// (same spirit as `ScoringPolicy` and `LevelPolicy`).
abstract final class RecoveryPolicy {
  /// How far in the future the "surface now" notification is armed.
  /// The notification plugin only accepts dates strictly in the future.
  static const Duration surfaceDelay = Duration(seconds: 3);

  /// Safety limit for the catch-up loop. A recurring task whose phone
  /// was off for days produces one missed occurrence per pass (each
  /// resolved occurrence generates the next one, which may also be
  /// overdue). The next run continues if this limit is ever reached.
  static const int maxCatchUpPasses = 60;
}
