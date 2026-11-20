import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_month_grid.dart';

void main() {
  // June 2030 starts on a Saturday and has 30 days.
  final DateTime june = DateTime(2030, 6, 15);

  Future<void> pumpGrid(
    WidgetTester tester, {
    Map<int, int> counts = const <int, int>{},
    ValueChanged<DateTime>? onSelected,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarMonthGrid(
            selectedDay: june,
            taskCountByDay: counts,
            onSelected: onSelected ?? (_) {},
            onPreviousMonth: onPrevious ?? () {},
            onNextMonth: onNext ?? () {},
          ),
        ),
      ),
    );
  }

  test('monthLabel is capitalised and has the year', () {
    expect(CalendarMonthGrid.monthLabel(june), 'Junho 2030');
    expect(CalendarMonthGrid.monthLabel(DateTime(2031, 3, 1)), 'Março 2031');
  });

  test('daysInMonth handles short months and leap years', () {
    expect(CalendarMonthGrid.daysInMonth(DateTime(2030, 6)), 30);
    expect(CalendarMonthGrid.daysInMonth(DateTime(2030, 2)), 28);
    expect(CalendarMonthGrid.daysInMonth(DateTime(2032, 2)), 29);
    expect(CalendarMonthGrid.daysInMonth(DateTime(2030, 12)), 31);
  });

  testWidgets('shows every day of the month exactly once', (
    WidgetTester tester,
  ) async {
    await pumpGrid(tester);

    expect(find.text('Junho 2030'), findsOneWidget);
    for (int day = 1; day <= 30; day++) {
      expect(find.text('$day'), findsOneWidget, reason: 'day $day');
    }
    expect(find.text('31'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('tapping a day reports it', (WidgetTester tester) async {
    final List<DateTime> selected = <DateTime>[];
    await pumpGrid(tester, onSelected: selected.add);

    await tester.tap(find.text('20'));

    expect(selected, <DateTime>[DateTime(2030, 6, 20)]);
  });

  testWidgets('the arrows report previous and next month', (
    WidgetTester tester,
  ) async {
    int previous = 0;
    int next = 0;
    await pumpGrid(
      tester,
      onPrevious: () => previous++,
      onNext: () => next++,
    );

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.tap(find.byTooltip('Mês seguinte'));
    await tester.tap(find.byTooltip('Mês seguinte'));

    expect(previous, 1);
    expect(next, 2);
  });

  testWidgets('days with tasks are announced with their count', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpGrid(tester, counts: <int, int>{10: 1, 12: 3});

    expect(find.bySemanticsLabel('Dia 10, 1 tarefa'), findsOneWidget);
    expect(find.bySemanticsLabel('Dia 12, 3 tarefas'), findsOneWidget);
    expect(find.bySemanticsLabel('Dia 11'), findsOneWidget);
    expect(find.bySemanticsLabel('Dia 15, seleccionado'), findsOneWidget);
    handle.dispose();
  });
}
