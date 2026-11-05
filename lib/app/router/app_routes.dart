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

  // Bottom-navigation destinations (besides home).
  static const String tasks = '/tasks';
  static const String tasksName = 'tasks';

  static const String calendar = '/calendar';
  static const String calendarName = 'calendar';

  static const String progress = '/progress';
  static const String progressName = 'progress';

  static const String profile = '/profile';
  static const String profileName = 'profile';

  /// Child route of the Perfil branch (the link to it arrives with the
  /// Perfil screen).
  static const String profileInsights = '/profile/insights';
  static const String profileInsightsName = 'profileInsights';

  static const String taskCreate = '/tasks/create';
  static const String taskCreateName = 'taskCreate';

  static const String alarm = '/alarm/:occurrenceId';
  static const String alarmName = 'alarm';
}
