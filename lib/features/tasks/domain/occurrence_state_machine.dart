import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import 'occurrence_status.dart';

/// Validates and applies [OccurrenceStatus] transitions (master spec
/// §11). Independent of UI and persistence — a pure function of
/// (current status, requested status).
///
/// `cancelled` is reachable from `scheduled` and `snoozed` (e.g. the
/// parent task gets archived/deleted) even though master spec §11's
/// transition list doesn't spell it out explicitly — otherwise
/// `cancelled` would be a status nothing could ever reach.
abstract final class OccurrenceStateMachine {
  static const Map<OccurrenceStatus, Set<OccurrenceStatus>> _validTransitions =
      <OccurrenceStatus, Set<OccurrenceStatus>>{
    OccurrenceStatus.scheduled: <OccurrenceStatus>{
      OccurrenceStatus.triggered,
      OccurrenceStatus.cancelled,
    },
    OccurrenceStatus.triggered: <OccurrenceStatus>{
      OccurrenceStatus.completed,
      OccurrenceStatus.snoozed,
      OccurrenceStatus.declined,
      OccurrenceStatus.missed,
    },
    OccurrenceStatus.snoozed: <OccurrenceStatus>{
      OccurrenceStatus.scheduled,
      OccurrenceStatus.cancelled,
    },
    OccurrenceStatus.completed: <OccurrenceStatus>{},
    OccurrenceStatus.declined: <OccurrenceStatus>{},
    OccurrenceStatus.missed: <OccurrenceStatus>{},
    OccurrenceStatus.cancelled: <OccurrenceStatus>{},
  };

  /// Whether the domain allows moving from [from] to [to] directly.
  static bool canTransition(OccurrenceStatus from, OccurrenceStatus to) =>
      _validTransitions[from]?.contains(to) ?? false;

  /// The terminal (no further transitions possible) statuses.
  static bool isTerminal(OccurrenceStatus status) =>
      _validTransitions[status]?.isEmpty ?? true;

  /// Returns [to] wrapped in [Success] if the transition is valid,
  /// or a [SchedulingFailure] if not.
  static Result<OccurrenceStatus> transition(
    OccurrenceStatus from,
    OccurrenceStatus to,
  ) {
    if (!canTransition(from, to)) {
      return Fail<OccurrenceStatus>(
        SchedulingFailure('Invalid occurrence transition: $from -> $to'),
      );
    }
    return Success<OccurrenceStatus>(to);
  }
}
