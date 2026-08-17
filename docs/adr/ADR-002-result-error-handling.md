# ADR-002 — Result<T> + sealed Failure instead of thrown exceptions

## Status
Accepted (Fase 0)

## Context
Master spec §16 forbids swallowing exceptions (`catch (_) {}`) and
requires explicit, typed failures across Task Engine, Scheduler,
Performance Engine, etc.

## Decision
- `Result<T>` is a Dart 3 `sealed class` with two variants,
  `Success<T>` and `Fail<T>`.
- `Failure` is a sealed class with one subtype per failure category
  (`ValidationFailure`, `DatabaseFailure`, `AlarmFailure`,
  `PermissionFailure`, `SchedulingFailure`, `PlatformFailure`,
  `UnknownFailure`).
- Neither type uses Freezed — they have no need for `copyWith`/JSON
  serialization, and Dart 3's built-in `sealed`+pattern matching
  (`switch`) already gives exhaustiveness checking for free.
- Freezed is reserved for actual data/value models (see
  `AppEnvironment` in `app/config`, and future domain models in
  Fase 2+).

## Consequences
- Every Application/Domain method that can fail returns
  `Result<T>` — callers are forced to handle both branches via
  `when()` or pattern matching.
- Adding a new failure category is a one-line addition, and the
  compiler flags any `switch` that doesn't handle it.
