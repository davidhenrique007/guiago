/// Pure logic for whether an occurrence's tolerance window has
/// elapsed (master spec §4/§24 — an alarm left unanswered past its
/// tolerance should be treated as MISSED).
///
/// Deliberately Flutter/Infrastructure-free — [AlarmRingController]
/// (Application layer) uses this to decide when to call
/// `TaskEngine.markMissed()` while the alarm screen is still open.
/// Background/OS-level enforcement (checking tolerance even when the
/// app isn't running) is a Fase 7 concern — see ADR-008.
abstract final class ToleranceChecker {
  static bool hasExpired({
    required DateTime triggeredAt,
    required int toleranceMinutes,
    required DateTime now,
  }) {
    final DateTime deadline =
        triggeredAt.add(Duration(minutes: toleranceMinutes));
    return now.isAfter(deadline);
  }

  /// How long until the tolerance window closes, from [now]. Negative
  /// (or zero) once it has already expired.
  static Duration remaining({
    required DateTime triggeredAt,
    required int toleranceMinutes,
    required DateTime now,
  }) {
    final DateTime deadline =
        triggeredAt.add(Duration(minutes: toleranceMinutes));
    return deadline.difference(now);
  }
}
