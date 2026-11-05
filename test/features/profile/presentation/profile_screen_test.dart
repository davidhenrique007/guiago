import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_router.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpProfile(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          builder: (BuildContext context, GoRouterState state) =>
              const ProfileScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'insights',
              name: AppRoutes.profileInsightsName,
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('INSIGHTS')),
            ),
          ],
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

  testWidgets('shows the name, objective and the saved preferences', (
    WidgetTester tester,
  ) async {
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(
        userName: 'Ana',
        mainObjective: 'Estudar todos os dias',
        notificationsEnabled: false,
        defaultSnoozeMinutes: 5,
        defaultToleranceMinutes: 30,
      ),
    );

    await pumpProfile(tester);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // avatar initial
    expect(find.text('Estudar todos os dias'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('Desativadas'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
  });

  testWidgets('falls back to neutral text when nothing was saved', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('Sem nome'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('Sem objetivo definido'), findsOneWidget);
  });

  testWidgets('tapping Insights opens the insights route', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('INSIGHTS'), findsOneWidget);
  });
}
