import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiago/app/router/app_placeholder_screen.dart';
import 'package:guiago/app/router/app_shell.dart';
import 'package:guiago/app/router/shell_swipe_detector.dart';

Widget _screen(String name) =>
    AppPlaceholderScreen(title: 'Ecrã $name', icon: Icons.circle_outlined);

GoRouter _router({String initialLocation = '/home'}) {
  return GoRouter(
    initialLocation: initialLocation,
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
                      _screen(name),
                  routes: <RouteBase>[
                    if (name == 'profile')
                      GoRoute(
                        path: 'detail',
                        builder: (BuildContext context, GoRouterState state) =>
                            _screen('detail'),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

void main() {
  group('ShellSwipeDetector', () {
    Future<List<int>> pumpDetector(
      WidgetTester tester, {
      required int currentIndex,
      bool enabled = true,
    }) async {
      final List<int> changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ShellSwipeDetector(
            currentIndex: currentIndex,
            itemCount: 5,
            enabled: enabled,
            onChanged: changes.add,
            child: const SizedBox.expand(child: Text('conteúdo')),
          ),
        ),
      );
      return changes;
    }

    testWidgets('swiping left goes to the next tab', (
      WidgetTester tester,
    ) async {
      final List<int> changes = await pumpDetector(tester, currentIndex: 1);

      await tester.fling(find.text('conteúdo'), const Offset(-300, 0), 1000);

      expect(changes, <int>[2]);
    });

    testWidgets('swiping right goes to the previous tab', (
      WidgetTester tester,
    ) async {
      final List<int> changes = await pumpDetector(tester, currentIndex: 3);

      await tester.fling(find.text('conteúdo'), const Offset(300, 0), 1000);

      expect(changes, <int>[2]);
    });

    testWidgets('does not wrap around at either end', (
      WidgetTester tester,
    ) async {
      final List<int> first = await pumpDetector(tester, currentIndex: 0);
      await tester.fling(find.text('conteúdo'), const Offset(300, 0), 1000);
      expect(first, isEmpty);

      final List<int> last = await pumpDetector(tester, currentIndex: 4);
      await tester.fling(find.text('conteúdo'), const Offset(-300, 0), 1000);
      expect(last, isEmpty);
    });

    testWidgets('ignores a slow drag', (WidgetTester tester) async {
      final List<int> changes = await pumpDetector(tester, currentIndex: 1);

      await tester.fling(find.text('conteúdo'), const Offset(-300, 0), 50);

      expect(changes, isEmpty);
    });

    testWidgets('does nothing when disabled', (WidgetTester tester) async {
      final List<int> changes = await pumpDetector(
        tester,
        currentIndex: 1,
        enabled: false,
      );

      await tester.fling(find.text('conteúdo'), const Offset(-300, 0), 1000);

      expect(changes, isEmpty);
    });
  });

  group('AppShell swipe', () {
    testWidgets('swiping moves between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
      await tester.pumpAndSettle();
      expect(find.text('Ecrã home'), findsOneWidget);

      await tester.fling(find.text('Ecrã home'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Ecrã tasks'), findsOneWidget);

      await tester.fling(find.text('Ecrã tasks'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Ecrã home'), findsOneWidget);
    });

    testWidgets('does not swipe away from a nested screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(initialLocation: '/profile/detail'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ecrã detail'), findsOneWidget);

      await tester.fling(find.text('Ecrã detail'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Ecrã detail'), findsOneWidget);
    });
  });
}
