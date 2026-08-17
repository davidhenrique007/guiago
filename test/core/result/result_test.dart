import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';

void main() {
  group('Result<T>', () {
    test('Success exposes the value via valueOrNull', () {
      const Result<int> result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Fail exposes the failure via failureOrNull', () {
      const Failure failure = ValidationFailure('title is required');
      const Result<int> result = Fail<int>(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('when() dispatches to the matching branch', () {
      const Result<int> success = Success<int>(10);
      const Result<int> fail = Fail<int>(DatabaseFailure('disk full'));

      final String successOutcome = success.when(
        success: (int v) => 'ok:$v',
        failure: (Failure f) => 'err:${f.message}',
      );
      final String failOutcome = fail.when(
        success: (int v) => 'ok:$v',
        failure: (Failure f) => 'err:${f.message}',
      );

      expect(successOutcome, 'ok:10');
      expect(failOutcome, 'err:disk full');
    });

    test('map() transforms a Success value and preserves a Fail', () {
      const Result<int> success = Success<int>(2);
      const Result<int> fail = Fail<int>(UnknownFailure('boom'));

      final Result<String> mappedSuccess = success.map((int v) => 'value=$v');
      final Result<String> mappedFail = fail.map((int v) => 'value=$v');

      expect(mappedSuccess.valueOrNull, 'value=2');
      expect(mappedFail.isFailure, isTrue);
      expect(mappedFail.failureOrNull, isA<UnknownFailure>());
    });
  });
}
