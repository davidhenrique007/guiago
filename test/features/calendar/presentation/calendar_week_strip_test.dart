import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_week_strip.dart';

void main() {
  group('weekOf', () {
    test('runs Monday to Sunday around the given day', () {
      // 2026-08-14 is a Friday.
      final List<DateTime> week = CalendarWeekStrip.weekOf(DateTime(2026, 8, 14));

      expect(week, hasLength(7));
      expect(week.first, DateTime(2026, 8, 10));
      expect(week.last, DateTime(2026, 8, 16));
      expect(week.first.weekday, DateTime.monday);
      expect(week.last.weekday, DateTime.sunday);
    });

    test('a Sunday belongs to the week that started the Monday before', () {
      // 2026-03-01 is a Sunday.
      final List<DateTime> week = CalendarWeekStrip.weekOf(DateTime(2026, 3, 1));

      expect(week.first, DateTime(2026, 2, 23));
      expect(week.last, DateTime(2026, 3, 1));
    });
  });

  testWidgets('tapping a day reports it, and the selected one is labelled', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    DateTime? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarWeekStrip(
            selectedDay: DateTime(2026, 8, 14),
            onSelected: (DateTime day) => tapped = day,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Sexta-feira 14, seleccionado'), findsOneWidget);
    expect(find.bySemanticsLabel('Sábado 15'), findsOneWidget);

    await tester.tap(find.text('12'));
    await tester.pump();

    expect(tapped, DateTime(2026, 8, 12));
    semantics.dispose();
  });
}
