/// A [TaskOccurrence]'s lifecycle state (master spec §11).
///
/// Transitions between these are only ever made through
/// [OccurrenceStateMachine] — never assigned directly by UI or
/// repository code.
enum OccurrenceStatus {
  scheduled,
  triggered,
  snoozed,
  completed,
  declined,
  missed,
  cancelled,
}
