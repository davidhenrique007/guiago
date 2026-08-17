import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.dart';

/// Root router provider. Fase 1 will add the real onboarding/home/task
/// routes; Fase 0 only proves navigation is wired end to end.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (BuildContext context, GoRouterState state) =>
            const _BootstrapPlaceholderScreen(),
      ),
    ],
  );
});

/// Temporary landing screen, replaced by the real Home in Fase 6/22.
/// Its only job right now is to prove the app boots and routes.
class _BootstrapPlaceholderScreen extends StatelessWidget {
  const _BootstrapPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('GuiaGo — Fase 0: Foundation'),
      ),
    );
  }
}
