import 'recurrence_rule.dart';

/// Computes the next occurrence date/time for a recurring [Task]
/// (master spec §12).
///
/// Deliberately generates ONE occurrence at a time — call this again
/// only after the current occurrence resolves (completed / declined
/// / missed). Never pre-generates a batch, so there is no risk of
/// runaway occurrence generation.
abstract final class RecurrenceEngine {
  /// Returns the next scheduled date/time strictly after [after],
  /// preserving the time-of-day and (for `weekly`) the weekday from
  /// [anchor] — the task's original scheduled time. Returns `null`
  /// for [RecurrenceRule.none] (a one-off task has no next
  /// occurrence).
  static DateTime? nextOccurrenceAfter({
    required RecurrenceRule recurrenceRule,
    required DateTime anchor,
    required DateTime after,
  }) {
    return switch (recurrenceRule) {
      RecurrenceNone() => null,
      RecurrenceDaily() => _nextDaily(anchor, after),
      RecurrenceWeekly() =>
        _nextOnWeekdays(<int>{anchor.weekday}, anchor, after),
      RecurrenceCustomDays(:final weekdays) =>
        _nextOnWeekdays(weekdays, anchor, after),
    };
  }

  static DateTime _nextDaily(DateTime anchor, DateTime after) {
    DateTime candidate = _atTimeOfDay(after, anchor);
    if (!candidate.isAfter(after)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime _nextOnWeekdays(
    Set<int> weekdays,
    DateTime anchor,
    DateTime after,
  ) {
    assert(weekdays.isNotEmpty, 'weekdays must not be empty');
    DateTime candidate = _atTimeOfDay(after, anchor);
    // At most 8 days needed to guarantee we cross a full week and
    // find a matching weekday strictly after `after`.
    for (int i = 0; i < 8; i++) {
      if (weekdays.contains(candidate.weekday) && candidate.isAfter(after)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    // Unreachable: weekdays is non-empty and every weekday recurs
    // within 7 days, so the loop above always returns first.
    throw StateError(
      'RecurrenceEngine: no matching weekday found for $weekdays',
    );
  }

  static DateTime _atTimeOfDay(DateTime date, DateTime timeSource) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeSource.hour,
      timeSource.minute,
    );
  }
}
