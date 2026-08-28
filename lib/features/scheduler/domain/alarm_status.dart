/// An [AlarmRecord]'s lifecycle state (master spec §13).
///
/// Deliberately smaller than [OccurrenceStatus] — the Scheduler only
/// needs to know whether the *native* alarm is still armed, already
/// fired, or was cancelled. What happened to the occurrence
/// afterwards (completed/declined/missed) is tracked separately by
/// the Task Engine.
enum AlarmStatus { scheduled, fired, cancelled }
