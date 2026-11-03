import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
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
