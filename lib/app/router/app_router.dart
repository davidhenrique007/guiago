import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alarms/presentation/screens/alarm_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/tasks/presentation/screens/task_create_screen.dart';

part 'app_routes.dart';

/// Root router provider.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcomeName,
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskCreate,
        name: AppRoutes.taskCreateName,
        builder: (BuildContext context, GoRouterState state) =>
            const TaskCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.alarm,
        name: AppRoutes.alarmName,
        builder: (BuildContext context, GoRouterState state) => AlarmScreen(
          occurrenceId: state.pathParameters['occurrenceId']!,
        ),
      ),
    ],
  );
});
