import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Temporary body for a navigation destination whose real screen has
/// not been built yet. Keeps every tab of the bottom bar reachable
/// while the screens land one lote at a time; each one is replaced by
/// its feature screen and this widget is deleted when none is left.
class AppPlaceholderScreen extends StatelessWidget {
  const AppPlaceholderScreen({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: AppEmptyState(
          title: 'Em breve',
          message: 'Este ecrã está a ser preparado.',
          icon: icon,
        ),
      ),
    );
  }
}
