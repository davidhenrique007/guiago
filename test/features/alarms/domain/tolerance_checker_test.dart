import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/alarms/domain/tolerance_checker.dart';

void main() {
  group('ToleranceChecker.hasExpired', () {
    test('false while still within the tolerance window', () {
      final DateTime triggeredAt = DateTime(2026, 8, 24, 9, 0);
      final bool expired = ToleranceChecker.hasExpired(
        triggeredAt: triggeredAt,
        toleranceMinutes: 15,
        now: DateTime(2026, 8, 24, 9, 10),
      );
      expect(expired, isFalse);
    });

    test('true once the tolerance window has passed', () {
      final DateTime triggeredAt = DateTime(2026, 8, 24, 9, 0);
      final bool expired = ToleranceChecker.hasExpired(
        triggeredAt: triggeredAt,
        toleranceMinutes: 15,
        now: DateTime(2026, 8, 24, 9, 16),
      );
      expect(expired, isTrue);
    });

    test('false exactly at the deadline (strictly after, not at)', () {
      final DateTime triggeredAt = DateTime(2026, 8, 24, 9, 0);
      final bool expired = ToleranceChecker.hasExpired(
        triggeredAt: triggeredAt,
        toleranceMinutes: 15,
        now: DateTime(2026, 8, 24, 9, 15),
      );
      expect(expired, isFalse);
    });
  });

  group('ToleranceChecker.remaining', () {
    test('is positive before the deadline', () {
      final Duration remaining = ToleranceChecker.remaining(
        triggeredAt: DateTime(2026, 8, 24, 9, 0),
        toleranceMinutes: 15,
        now: DateTime(2026, 8, 24, 9, 5),
      );
      expect(remaining, const Duration(minutes: 10));
    });

    test('is negative after the deadline', () {
      final Duration remaining = ToleranceChecker.remaining(
        triggeredAt: DateTime(2026, 8, 24, 9, 0),
        toleranceMinutes: 15,
        now: DateTime(2026, 8, 24, 9, 20),
      );
      expect(remaining.isNegative, isTrue);
    });
  });
}
