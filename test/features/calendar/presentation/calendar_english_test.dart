import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/app/router/app_shell.dart';
import 'package:guiago/design_system/components/app_bottom_nav.dart';
import 'package:guiago/features/calendar/domain/calendar_view_mode.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_day_navigator.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_view_selector.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_week_strip.dart';
import 'package:guiago/features/calendar/presentation/widgets/calendar_year_grid.dart';
import 'package:guiago/l10n/app_localizations.dart';

Widget _english(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  final DateTime day = DateTime(2030, 6, 12); // a Wednesday

  testWidgets('the view selector says Day / Month / Year', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _english(
        CalendarViewSelector(
          selected: CalendarViewMode.day,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Dia'), findsNothing);
  });

  testWidgets('the day navigator has English tooltips and date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _english(
        CalendarDayNavigator(day: day, onPrevious: () {}, onNext: () {}),
      ),
    );

    expect(find.text('Wednesday, June 12'), findsOneWidget);
    expect(find.byTooltip('Previous day'), findsOneWidget);
    expect(find.byTooltip('Next day'), findsOneWidget);
  });

  testWidgets('the week strip uses English weekday abbreviations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _english(CalendarWeekStrip(selectedDay: day, onSelected: (_) {})),
    );

    expect(find.text('MON'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('SEG'), findsNothing);
  });

  testWidgets('the month grid has an English title and semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _english(
        CalendarMonthGrid(
          selectedDay: day,
          taskCountByDay: const <int, int>{12: 3},
          onSelected: (_) {},
          onPreviousMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );

    expect(find.text('June 2030'), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.bySemanticsLabel('Day 12, 3 tasks, selected'), findsOneWidget);
  });

  testWidgets('the year grid has English months and counts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _english(
        CalendarYearGrid(
          year: 2030,
          taskCountByMonth: const <int, int>{1: 1, 2: 4},
          onMonthSelected: (_) {},
          onPreviousYear: () {},
          onNextYear: () {},
        ),
      ),
    );

    expect(find.text('January'), findsOneWidget);
    expect(find.text('1 task'), findsOneWidget);
    expect(find.text('4 tasks'), findsOneWidget);
    expect(find.byTooltip('Next year'), findsOneWidget);
  });

  test('the bottom bar is named in the chosen language', () {
    final List<AppBottomNavItem> en = AppShell.itemsFor(
      AppLocalizations.forLocale(const Locale('en')),
    );

    expect(
      en.map((AppBottomNavItem i) => i.label).toList(),
      <String>['Home', 'Tasks', 'Calendar', 'Progress', 'Profile'],
    );
    expect(
      AppShell.items.map((AppBottomNavItem i) => i.label).toList(),
      <String>['Início', 'Tarefas', 'Calendário', 'Progresso', 'Perfil'],
    );
  });
}
