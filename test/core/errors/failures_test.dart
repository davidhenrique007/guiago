import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';

void main() {
  group('Failure', () {
    test('subtypes carry their message and are Failure instances', () {
      const List<Failure> failures = <Failure>[
        ValidationFailure('bad input'),
        DatabaseFailure('write failed'),
        AlarmFailure('could not schedule'),
        PermissionFailure('notifications denied'),
        SchedulingFailure('invalid recurrence'),
        PlatformFailure('channel error'),
        UnknownFailure('unexpected'),
      ];

      for (final Failure failure in failures) {
        expect(failure.message, isNotEmpty);
        expect(failure.toString(), contains(failure.message));
      }
    });

    test('preserves the original cause when provided', () {
      final Exception cause = Exception('native error');
      final AlarmFailure failure =
          AlarmFailure('scheduling failed', cause: cause);

      expect(failure.cause, cause);
    });
  });
}
