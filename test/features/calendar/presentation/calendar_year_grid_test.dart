import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_year_grid.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Map<int, int> counts = const <int, int>{},
    ValueChanged<DateTime>? onMonth,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarYearGrid(
            year: 2027,
            taskCountByMonth: counts,
            onMonthSelected: onMonth ?? (_) {},
            onPreviousYear: onPrevious ?? () {},
            onNextYear: onNext ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the year and the twelve months', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    expect(find.text('2027'), findsOneWidget);
    for (final String month in <String>[
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ]) {
      expect(find.text(month), findsOneWidget);
    }
  });

  testWidgets('marks the months that have tasks', (WidgetTester tester) async {
    await pump(tester, counts: <int, int>{1: 1, 7: 4});

    expect(find.text('1 tarefa'), findsOneWidget);
    expect(find.text('4 tarefas'), findsOneWidget);
  });

  testWidgets('tapping a month reports its first day', (
    WidgetTester tester,
  ) async {
    DateTime? picked;
    await pump(tester, onMonth: (DateTime d) => picked = d);

    await tester.tap(find.text('Março'));

    expect(picked, DateTime(2027, 3));
  });

  testWidgets('the arrows report previous and next year', (
    WidgetTester tester,
  ) async {
    int previous = 0;
    int next = 0;
    await pump(
      tester,
      onPrevious: () => previous++,
      onNext: () => next++,
    );

    await tester.tap(find.byTooltip('Ano anterior'));
    await tester.tap(find.byTooltip('Ano seguinte'));
    await tester.tap(find.byTooltip('Ano seguinte'));

    expect(previous, 1);
    expect(next, 2);
  });
}
