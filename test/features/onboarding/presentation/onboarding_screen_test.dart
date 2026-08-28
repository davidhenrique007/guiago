import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpOnboarding(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/onboarding',
      routes: <RouteBase>[
        GoRoute(
          path: '/onboarding',
          builder: (BuildContext context, GoRouterState state) =>
              const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('HOME')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first step (profile) with no back button', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.text('Como quer ser chamado?'), findsOneWidget);
    expect(find.text('Voltar'), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('Continuar advances a step and reveals the back button', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Qual é o seu objetivo principal?'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('Voltar returns to the previous step', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Como quer ser chamado?'), findsOneWidget);
  });

  testWidgets('completing the last step saves settings and navigates home', (
    WidgetTester tester,
  ) async {
    await pumpOnboarding(tester);

    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Concluir'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });
}
