import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/calendar/application/calendar_controller.dart';
import '../features/calendar/application/calendar_month_controller.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/home/application/home_controller.dart';
import '../features/insights/application/insights_controller.dart';
import '../features/tasks/application/tasks_controller.dart';

/// Reloads every tab that shows tasks or numbers derived from them.
///
/// The shell keeps all tabs alive, so after a task is created, edited,
/// removed, completed or snoozed, the other tabs would otherwise keep
/// showing stale data until the user pulled to refresh.
void refreshTaskViews(WidgetRef ref) {
  ref.invalidate(tasksControllerProvider);
  ref.invalidate(homeControllerProvider);
  ref.invalidate(calendarControllerProvider);
  ref.invalidate(calendarMonthControllerProvider);
  ref.invalidate(dashboardControllerProvider);
  ref.invalidate(insightsControllerProvider);
}
