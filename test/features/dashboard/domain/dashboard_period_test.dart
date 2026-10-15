import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/dashboard/domain/dashboard_period.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 15, 14, 30);

  group('DashboardPeriod.days', () {
    test('today is 1, week is 7, month is 30', () {
      expect(DashboardPeriod.today.days, 1);
      expect(DashboardPeriod.week.days, 7);
      expect(DashboardPeriod.month.days, 30);
    });
  });

  group('DashboardPeriod.rangeAt', () {
    test('today spans midnight to the last instant of the day', () {
      final range = DashboardPeriod.today.rangeAt(now);

      expect(range.start, DateTime(2026, 3, 15));
      expect(
        range.end.add(const Duration(microseconds: 1)),
        DateTime(2026, 3, 16),
      );
    });

    test('week starts 6 days before today', () {
      final range = DashboardPeriod.week.rangeAt(now);

      expect(range.start, DateTime(2026, 3, 9));
    });

    test('month starts 29 days before today', () {
      final range = DashboardPeriod.month.rangeAt(now);

      expect(range.start, DateTime(2026, 2, 14));
    });

    test('the window crosses month boundaries correctly', () {
      final range = DashboardPeriod.week.rangeAt(DateTime(2026, 3, 3, 8));

      expect(range.start, DateTime(2026, 2, 25));
    });
  });
}
