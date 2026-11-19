/// What the recovery pass must do with one live occurrence (Fase 7).
enum RecoveryAction {
  /// The alarm moment is still in the future: just re-arm the alarm.
  reschedule,

  /// The alarm moment already passed (phone off, app killed) but the
  /// tolerance window is still open: notify right away so the user can
  /// still act on it.
  surfaceNow,

  /// The tolerance window closed while nobody was looking: the
  /// occurrence must be resolved as missed.
  markMissed,

  /// Nothing to do (already terminal, or a transient state).
  leaveAsIs,
}
