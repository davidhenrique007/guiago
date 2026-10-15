part of 'app_router.dart';

/// Centralized route paths and names. Every feature adds its routes
/// here instead of hardcoding path strings at call sites.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String splashName = 'splash';

  static const String welcome = '/welcome';
  static const String welcomeName = 'welcome';

  static const String onboarding = '/onboarding';
  static const String onboardingName = 'onboarding';

  static const String home = '/home';
  static const String homeName = 'home';

  static const String dashboard = '/dashboard';
  static const String dashboardName = 'dashboard';

  static const String taskCreate = '/tasks/create';
  static const String taskCreateName = 'taskCreate';

  static const String alarm = '/alarm/:occurrenceId';
  static const String alarmName = 'alarm';
}
