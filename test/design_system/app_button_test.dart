import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/design_system/design_system.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  for (final AppButtonVariant variant in AppButtonVariant.values) {
    testWidgets('${variant.name} shows its label and reacts to taps', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        AppButton(
          label: 'Ação',
          variant: variant,
          icon: Icons.check_rounded,
          onPressed: () => taps++,
        ),
      );

      await tester.tap(find.text('Ação'));

      expect(taps, 1);
    });
  }

  testWidgets('caution and danger draw an outline, the others do not', (
    WidgetTester tester,
  ) async {
    BorderSide? sideOf(WidgetTester t) {
      final ElevatedButton button = t.widget(find.byType(ElevatedButton));
      return button.style?.side?.resolve(<WidgetState>{});
    }

    await _pump(
      tester,
      const AppButton(
        label: 'A',
        variant: AppButtonVariant.caution,
        onPressed: null,
      ),
    );
    expect(sideOf(tester), isNotNull);

    await _pump(
      tester,
      const AppButton(label: 'A', onPressed: null),
    );
    expect(sideOf(tester), isNull);
  });
}
