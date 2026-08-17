/// Base type for every domain-level failure in GuiaGo.
///
/// The Domain layer never throws raw exceptions across its boundaries —
/// it returns a [Failure] wrapped in a [Result]. See `core/result/result.dart`.
///
/// This is a Dart 3 sealed class hierarchy (exhaustive, switch-friendly),
/// deliberately kept free of Freezed/codegen since it has no need for
/// copyWith/toJson — it is an internal error-signaling type, not a model.
sealed class Failure {
  const Failure(this.message, {this.cause});

  /// Human-readable (developer-facing) description of what went wrong.
  final String message;

  /// The original exception/error that triggered this failure, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Input failed a domain validation rule (e.g. empty task title).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// A local persistence (Drift/SQLite) operation failed.
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause});
}

/// Scheduling, cancelling, or rescheduling a native alarm failed.
final class AlarmFailure extends Failure {
  const AlarmFailure(super.message, {super.cause});
}

/// A required OS permission (notifications, exact alarms, etc.) was denied.
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

/// The Scheduler could not compute or apply a valid schedule.
final class SchedulingFailure extends Failure {
  const SchedulingFailure(super.message, {super.cause});
}

/// A platform channel / native API call failed.
final class PlatformFailure extends Failure {
  const PlatformFailure(super.message, {super.cause});
}

/// Anything that doesn't fit the categories above. Should be rare —
/// prefer adding a specific Failure subtype over reaching for this one.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}
