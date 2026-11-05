import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/design_system/design_system.dart';

Future<void> _pump(WidgetTester tester, AppTrendChart chart) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: chart))),
  );
}

void main() {
  testWidgets('default constructor keeps drawing all bars as before', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AppTrendChart(values: <double>[0.2, 1, -1]));

    final AppTrendChart chart = tester.widget(find.byType(AppTrendChart));
    expect(chart.highlightedIndices, isEmpty);
    expect(chart.dimColor, AppColors.border);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts highlighted bars and repaints when they change', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppTrendChart(
        values: <double>[0.2, 1, 0.5],
        highlightedIndices: <int>{1},
      ),
    );
    await _pump(
      tester,
      const AppTrendChart(
        values: <double>[0.2, 1, 0.5],
        highlightedIndices: <int>{1, 2},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('an empty list draws nothing and does not throw', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AppTrendChart(values: <double>[]));

    expect(tester.takeException(), isNull);
  });
}
