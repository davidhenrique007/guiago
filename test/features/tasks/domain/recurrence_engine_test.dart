import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/tasks/domain/recurrence_engine.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';

void main() {
  group('RecurrenceEngine.nextOccurrenceAfter', () {
    test('none never produces a next occurrence', () {
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.none(),
        anchor: anchor,
        after: anchor,
      );
      expect(next, isNull);
    });

    test('daily returns the same time-of-day on the following day', () {
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.daily(),
        anchor: anchor,
        after: anchor,
      );
      expect(next, DateTime(2026, 8, 25, 9, 0));
    });

    test('weekly returns the same weekday and time one week later', () {
      // 2026-08-24 is a Monday.
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.weekly(),
        anchor: anchor,
        after: anchor,
      );
      expect(next, DateTime(2026, 8, 31, 9, 0));
      expect(next!.weekday, DateTime.monday);
    });

    test('customDays finds the next matching weekday, wrapping the week', () {
      // 2026-08-24 (Mon) with customDays {Mon, Wed} -> next is Wed 08-26.
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.customDays(
          weekdays: <int>{DateTime.monday, DateTime.wednesday},
        ),
        anchor: anchor,
        after: anchor,
      );
      expect(next, DateTime(2026, 8, 26, 9, 0));
    });

    test('customDays wraps to next week when after is the last matching day',
        () {
      // After Wed 08-26, with {Mon, Wed} the next match is Mon 08-31.
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime after = DateTime(2026, 8, 26, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.customDays(
          weekdays: <int>{DateTime.monday, DateTime.wednesday},
        ),
        anchor: anchor,
        after: after,
      );
      expect(next, DateTime(2026, 8, 31, 9, 0));
    });

    test('never generates more than one occurrence per call', () {
      // A single call must return exactly one DateTime, not a list —
      // enforced structurally by the return type (DateTime?), but
      // this test documents the intent from master spec §12.
      final DateTime anchor = DateTime(2026, 8, 24, 9, 0);
      final DateTime? next = RecurrenceEngine.nextOccurrenceAfter(
        recurrenceRule: const RecurrenceRule.daily(),
        anchor: anchor,
        after: anchor,
      );
      expect(next, isA<DateTime>());
    });
  });
}
