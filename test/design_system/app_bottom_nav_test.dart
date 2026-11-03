import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/design_system/design_system.dart';

void main() {
  const List<AppBottomNavItem> items = <AppBottomNavItem>[
    AppBottomNavItem(label: 'Início', icon: Icons.home_outlined),
    AppBottomNavItem(label: 'Progresso', icon: Icons.bar_chart_rounded),
  ];

  testWidgets('renders every label and reports the tapped index', (
    WidgetTester tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: items,
            currentIndex: 0,
            onSelected: (int index) => selected = index,
          ),
        ),
      ),
    );

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Progresso'), findsOneWidget);

    await tester.tap(find.text('Progresso'));
    expect(selected, 1);
  });

  testWidgets('highlights only the current destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: items,
            currentIndex: 1,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final Icon home = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
    final Icon progress =
        tester.widget<Icon>(find.byIcon(Icons.bar_chart_rounded));

    expect(progress.color, AppColors.primary);
    expect(home.color, AppColors.textSecondary);
  });
}
