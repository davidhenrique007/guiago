import '../../../core/errors/failures.dart';

/// What one recovery run did. Plain immutable value.
class RecoveryReport {
  const RecoveryReport({
    this.rescheduled = 0,
    this.surfaced = 0,
    this.markedMissed = 0,
    this.failures = const <Failure>[],
  });

  static const RecoveryReport empty = RecoveryReport();

  /// Future occurrences whose alarm was re-armed.
  final int rescheduled;

  /// Overdue occurrences still inside their tolerance window that got
  /// an immediate notification.
  final int surfaced;

  /// Overdue occurrences resolved as missed.
  final int markedMissed;

  /// Per-occurrence problems (scheduling or state failures). A failure
  /// never aborts the run; the next run retries.
  final List<Failure> failures;

  /// True when occurrence statuses changed, so screens showing them
  /// should reload.
  bool get changedOccurrences => markedMissed > 0;

  bool get hasFailures => failures.isNotEmpty;
}
