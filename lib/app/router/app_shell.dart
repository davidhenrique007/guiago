import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/design_system.dart';
import 'app_router.dart';
import 'shell_swipe_detector.dart';

/// Frame around the five main destinations: the active branch on top,
/// the bottom bar below. Each branch keeps its own navigation stack
/// and state while the user switches tabs.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Order matches the branch order declared in `app_router.dart`.
  static const List<AppBottomNavItem> items = <AppBottomNavItem>[
    AppBottomNavItem(label: 'Início', icon: Icons.home_outlined),
    AppBottomNavItem(label: 'Tarefas', icon: Icons.check_box_outlined),
    AppBottomNavItem(label: 'Calendário', icon: Icons.calendar_today_outlined),
    AppBottomNavItem(label: 'Progresso', icon: Icons.bar_chart_rounded),
    AppBottomNavItem(label: 'Perfil', icon: Icons.person_outline),
  ];

  /// The root screen of each tab. Swiping between tabs only works on
  /// these: on a nested screen (e.g. Insights) it would throw the user
  /// out of where they are.
  static const List<String> _rootPaths = <String>[
    AppRoutes.home,
    AppRoutes.tasks,
    AppRoutes.calendar,
    AppRoutes.progress,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final bool atTabRoot = _rootPaths.contains(
      GoRouterState.of(context).matchedLocation,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ShellSwipeDetector(
        currentIndex: navigationShell.currentIndex,
        itemCount: items.length,
        enabled: atTabRoot,
        onChanged: navigationShell.goBranch,
        child: navigationShell,
      ),
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onSelected: (int index) => navigationShell.goBranch(
          index,
          // Tapping the active tab again returns to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
