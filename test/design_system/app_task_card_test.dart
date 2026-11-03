import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/design_system/design_system.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('shows time, title and status', (WidgetTester tester) async {
    await _pump(
      tester,
      const AppTaskCard(
        time: '14:00',
        title: 'Entregar relatório',
        statusLabel: 'Pendente',
        tone: AppTaskCardTone.medium,
      ),
    );

    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('Entregar relatório'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('done tone strikes the title and shows a check', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppTaskCard(
        time: '08:00',
        title: 'Preparar aula',
        statusLabel: 'Concluída',
        tone: AppTaskCardTone.done,
      ),
    );

    final Text title = tester.widget<Text>(find.text('Preparar aula'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('invokes onTap', (WidgetTester tester) async {
    int taps = 0;
    await _pump(
      tester,
      AppTaskCard(
        time: '10:30',
        title: 'Reunião',
        statusLabel: 'Pendente',
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.text('Reunião'));
    expect(taps, 1);
  });
}
