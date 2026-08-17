import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/app/app.dart';

void main() {
  testWidgets('GuiaGoApp boots and renders the bootstrap screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: GuiaGoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('GuiaGo — Fase 0: Foundation'), findsOneWidget);
  });
}
