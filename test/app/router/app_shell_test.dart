import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_placeholder_screen.dart';
import 'package:guiago/app/router/app_shell.dart';
import 'package:guiago/design_system/design_system.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          for (final String name in <String>[
            'home',
            'tasks',
            'calendar',
            'progress',
            'profile',
          ])
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/$name',
                  builder: (BuildContext context, GoRouterState state) =>
                      AppPlaceholderScreen(
                    title: 'Ecrã $name',
                    icon: Icons.circle_outlined,
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('shows the five destinations and switches branch on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    for (final AppBottomNavItem item in AppShell.items) {
      expect(find.text(item.label), findsOneWidget);
    }
    expect(find.text('Ecrã home'), findsOneWidget);

    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();

    expect(find.text('Ecrã calendar'), findsOneWidget);
  });
}
