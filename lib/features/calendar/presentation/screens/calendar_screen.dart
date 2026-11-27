import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/refresh_task_views.dart';
import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/application/settings_controller.dart';
import '../../../onboarding/domain/day_window.dart';
import '../../../onboarding/domain/settings.dart';
import '../../application/calendar_controller.dart';
import '../../application/calendar_month_controller.dart';
import '../../application/calendar_year_controller.dart';
import '../../domain/calendar_day_snapshot.dart';
import '../../domain/calendar_month_snapshot.dart';
import '../../domain/calendar_task_item.dart';
import '../../domain/calendar_view_mode.dart';
import '../../domain/calendar_year_snapshot.dart';
import '../widgets/calendar_day_list.dart';
import '../widgets/calendar_day_navigator.dart';
import '../widgets/calendar_month_grid.dart';
import '../widgets/calendar_view_selector.dart';
import '../widgets/calendar_week_strip.dart';
import '../widgets/calendar_year_grid.dart';
import '../widgets/task_detail_sheet.dart';

/// The Calendar tab, with three views:
/// - Dia: the week strip, day arrows and the selected day's tasks;
/// - Mês: the month grid and the selected day's tasks;
/// - Ano: the twelve months, to plan ahead (tapping one opens it in Mês).
///
/// A task can be created for the selected day (today or later) with
/// "Nova tarefa"; it opens the same form as the Tasks tab with that date
/// filled in. Tapping a task opens its detail; editing and deleting stay
/// in the Tasks tab.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay = CalendarController.keyFor(DateTime.now());
  CalendarViewMode _view = CalendarViewMode.day;

  /// Moves to the previous/next month, keeping the day of month (or
  /// the last day of the target month when it is shorter).
  void _shiftMonth(int delta) {
    final DateTime target = DateTime(
      _selectedDay.year,
      _selectedDay.month + delta,
    );
    final int lastDay = CalendarMonthGrid.daysInMonth(target);
    setState(() {
      _selectedDay = DateTime(
        target.year,
        target.month,
        _selectedDay.day > lastDay ? lastDay : _selectedDay.day,
      );
    });
  }

  void _shiftDay(int delta) {
    setState(() {
      _selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + delta,
      );
    });
  }

  /// Moves to the same month/day of another year (clamped, so 29 Feb
  /// becomes 28 Feb in a common year).
  void _shiftYear(int delta) {
    final DateTime target = DateTime(
      _selectedDay.year + delta,
      _selectedDay.month,
    );
    final int lastDay = CalendarMonthGrid.daysInMonth(target);
    setState(() {
      _selectedDay = DateTime(
        target.year,
        target.month,
        _selectedDay.day > lastDay ? lastDay : _selectedDay.day,
      );
    });
  }

  /// Opens a month from the year view: the month view on the same day
  /// number when it is the current month, otherwise on the 1st.
  void _openMonth(DateTime firstOfMonth) {
    final DateTime today = CalendarController.keyFor(DateTime.now());
    final bool isCurrent =
        firstOfMonth.year == today.year && firstOfMonth.month == today.month;
    setState(() {
      _selectedDay = isCurrent ? today : firstOfMonth;
      _view = CalendarViewMode.month;
    });
  }

  bool get _canCreateForSelectedDay =>
      !_selectedDay.isBefore(CalendarController.keyFor(DateTime.now()));

  Future<void> _createTask() async {
    await context.pushNamed(AppRoutes.taskCreateName, extra: _selectedDay);
    if (!mounted) return;
    refreshTaskViews(ref);
  }

  void _refresh() {
    ref.read(calendarControllerProvider(_selectedDay).notifier).refresh();
    ref
        .read(calendarYearControllerProvider(_selectedDay.year).notifier)
        .refresh();
    ref
        .read(
          calendarMonthControllerProvider(
            CalendarMonthController.keyFor(_selectedDay),
          ).notifier,
        )
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CalendarDaySnapshot> snapshotAsync = ref.watch(
      calendarControllerProvider(_selectedDay),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.l10n.calendarTitle,
          style: AppTypography.titleLarge,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _refresh();
            await ref.read(calendarControllerProvider(_selectedDay).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              CalendarViewSelector(
                selected: _view,
                onChanged: (CalendarViewMode mode) =>
                    setState(() => _view = mode),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._body(snapshotAsync),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(AsyncValue<CalendarDaySnapshot> snapshotAsync) {
    if (_view == CalendarViewMode.year) return <Widget>[_yearGrid()];

    // The user's day (Perfil). While settings load, no window is shown
    // or marked rather than guessing one.
    final AsyncValue<Settings> settingsAsync =
        ref.watch(settingsControllerProvider);
    final DayWindow? dayWindow = switch (settingsAsync) {
      AsyncData<Settings>(:final value) => DayWindow.fromSettings(value),
      _ => null,
    };

    return <Widget>[
      if (_view == CalendarViewMode.day) ...<Widget>[
        CalendarWeekStrip(
          selectedDay: _selectedDay,
          onSelected: (DateTime day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: AppSpacing.sm),
        CalendarDayNavigator(
          day: _selectedDay,
          onPrevious: () => _shiftDay(-1),
          onNext: () => _shiftDay(1),
        ),
        if (dayWindow != null)
          Text(
            context.l10n.yourDay(dayWindow.label),
            textAlign: TextAlign.center,
            style: AppTypography.label,
          ),
      ] else ...<Widget>[
        _monthGrid(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.longDate(_selectedDay),
          style: AppTypography.bodyMedium,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      if (_canCreateForSelectedDay) ...<Widget>[
        AppButton(
          label: context.l10n.newTask,
          icon: Icons.add,
          onPressed: _createTask,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      // Pattern-matching, not `.when()` — same convention as
      // HomeScreen / DashboardScreen.
      switch (snapshotAsync) {
        AsyncData<CalendarDaySnapshot>(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (value.items.isNotEmpty) ...<Widget>[
                Text(
                  context.l10n.dayTasks(value.items.length),
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              CalendarDayList(
                dayWindow: dayWindow,
                items: value.items,
                onTap: (CalendarTaskItem item) => TaskDetailSheet.show(
                  context,
                  occurrenceId: item.occurrenceId,
                  title: item.title,
                ),
              ),
            ],
          ),
        AsyncError<CalendarDaySnapshot>() => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: AppErrorState(
              message: context.l10n.calendarLoadError,
              onRetry: _refresh,
            ),
          ),
        _ => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: AppLoadingState(),
          ),
      },
    ];
  }

  Widget _yearGrid() {
    final AsyncValue<CalendarYearSnapshot> yearAsync = ref.watch(
      calendarYearControllerProvider(_selectedDay.year),
    );
    // While the counts load (or if they fail) the months still work.
    final Map<int, int> counts = switch (yearAsync) {
      AsyncData<CalendarYearSnapshot>(:final value) => value.taskCountByMonth,
      _ => const <int, int>{},
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CalendarYearGrid(
          year: _selectedDay.year,
          taskCountByMonth: counts,
          onMonthSelected: _openMonth,
          onPreviousYear: () => _shiftYear(-1),
          onNextYear: () => _shiftYear(1),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.yearHint,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _monthGrid() {
    final AsyncValue<CalendarMonthSnapshot> monthAsync = ref.watch(
      calendarMonthControllerProvider(
        CalendarMonthController.keyFor(_selectedDay),
      ),
    );
    // While the counts load (or if they fail) the grid still works,
    // just without the task dots.
    final Map<int, int> counts = switch (monthAsync) {
      AsyncData<CalendarMonthSnapshot>(:final value) => value.taskCountByDay,
      _ => const <int, int>{},
    };
    return CalendarMonthGrid(
      selectedDay: _selectedDay,
      taskCountByDay: counts,
      onSelected: (DateTime day) => setState(() => _selectedDay = day),
      onPreviousMonth: () => _shiftMonth(-1),
      onNextMonth: () => _shiftMonth(1),
    );
  }
}
