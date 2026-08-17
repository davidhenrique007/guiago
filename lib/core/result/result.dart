import '../errors/failures.dart';

/// Functional result wrapper used across Application/Domain/Data layers.
///
/// Every use case, repository, and engine method that can fail returns
/// `Result<T>` instead of throwing. This keeps error handling explicit
/// and makes `catch (_) {}` unnecessary anywhere in the codebase.
sealed class Result<T> {
  const Result();

  /// True if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// True if this is a [Fail].
  bool get isFailure => this is Fail<T>;

  /// Returns the success value, or `null` if this is a [Fail].
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Fail<T>() => null,
      };

  /// Returns the failure, or `null` if this is a [Success].
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Fail<T>(:final failure) => failure,
      };

  /// Pattern-matches on the result, forcing both branches to be handled.
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) =>
      switch (this) {
        Success<T>(:final value) => success(value),
        Fail<T>(failure: final f) => failure(f), // <- linha corrigida
      };

  /// Transforms the success value, leaving a [Fail] untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Fail<T>(:final failure) => Fail<R>(failure),
      };

  /// Transforms the failure, leaving a [Success] untouched.
  Result<T> mapFailure(Result<T> Function(Failure failure) transform) =>
      switch (this) {
        Success<T>() => this,
        Fail<T>(:final failure) => transform(failure),
      };

  /// Executes [action] if this is a [Success].
  void forEach(void Function(T value) action) => switch (this) {
        Success<T>(:final value) => action(value),
        Fail<T>() => null,
      };

  /// Returns the success value or a default value.
  T getOrElse(T Function(Failure failure) orElse) => switch (this) {
        Success<T>(:final value) => value,
        Fail<T>(:final failure) => orElse(failure),
      };
}

/// A successful [Result] carrying a value of type [T].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// A failed [Result] carrying a [Failure].
///
/// Named `Fail` (not `Failure`) to avoid colliding with the `Failure`
/// error type it wraps.
final class Fail<T> extends Result<T> {
  const Fail(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fail<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Fail($failure)';
}
