import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/application/streak_engine.dart';
import 'package:guiago/features/performance/domain/day_outcome.dart';

void main() {
  const engine = StreakEngine();

  DayOutcome day(int dayOfMonth, DayFulfillment fulfillment) {
    return DayOutcome(
      date: DateTime(2026, 1, dayOfMonth),
      fulfillment: fulfillment,
    );
  }

  group('StreakEngine.calculate', () {
    test('empty list gives a zeroed streak', () {
      final status = engine.calculate(
        days: const [],
        calculatedAt: DateTime(2026, 1, 10),
      );

      expect(status.currentStreak, 0);
      expect(status.longestStreak, 0);
      expect(status.lastFulfilledDate, isNull);
    });

    test('consecutive fulfilled days build the streak', () {
      final days = [
        day(1, DayFulfillment.fulfilled),
        day(2, DayFulfillment.fulfilled),
        day(3, DayFulfillment.fulfilled),
      ];

      final status = engine.calculate(
        days: days,
        calculatedAt: DateTime(2026, 1, 3),
      );

      expect(status.currentStreak, 3);
      expect(status.longestStreak, 3);
      expect(status.lastFulfilledDate, DateTime(2026, 1, 3));
    });

    test('neutral days neither break nor extend the streak', () {
      final days = [
        day(1, DayFulfillment.fulfilled),
        day(2, DayFulfillment.neutral),
        day(3, DayFulfillment.fulfilled),
      ];

      final status = engine.calculate(
        days: days,
        calculatedAt: DateTime(2026, 1, 3),
      );

      expect(status.currentStreak, 2);
    });

    test('a broken day resets the current streak but keeps the longest', () {
      final days = [
        day(1, DayFulfillment.fulfilled),
        day(2, DayFulfillment.fulfilled),
        day(3, DayFulfillment.broken),
        day(4, DayFulfillment.fulfilled),
      ];

      final status = engine.calculate(
        days: days,
        calculatedAt: DateTime(2026, 1, 4),
      );

      expect(status.currentStreak, 1);
      expect(status.longestStreak, 2);
      expect(status.lastFulfilledDate, DateTime(2026, 1, 4));
    });

    test('lastFulfilledDate stays at the last fulfilled day after a break', () {
      final days = [
        day(1, DayFulfillment.fulfilled),
        day(2, DayFulfillment.broken),
      ];

      final status = engine.calculate(
        days: days,
        calculatedAt: DateTime(2026, 1, 2),
      );

      expect(status.currentStreak, 0);
      expect(status.lastFulfilledDate, DateTime(2026, 1, 1));
    });
  });
}
