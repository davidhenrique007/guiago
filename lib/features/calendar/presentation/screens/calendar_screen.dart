import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
import '../../application/calendar_controller.dart';
import '../../application/calendar_month_controller.dart';
import '../../domain/calendar_day_snapshot.dart';
import '../../domain/calendar_month_snapshot.dart';
import '../../domain/calendar_task_item.dart';
import '../../domain/calendar_view_mode.dart';
import '../widgets/calendar_day_list.dart';
import '../widgets/calendar_month_grid.dart';
import '../widgets/calendar_view_selector.dart';
import '../widgets/calendar_week_strip.dart';
import '../widgets/task_detail_sheet.dart';

/// The Calendar tab: a week strip or a month grid, and the occurrences
/// of the selected day below it. Read-only — tasks are created and
/// edited in the Tasks tab. Purely a view over [CalendarController]
/// and [CalendarMonthController].
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay = CalendarController.keyFor(DateTime.now());
  CalendarViewMode _view = CalendarViewMode.week;

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

  void _refresh() {
    ref.read(calendarControllerProvider(_selectedDay).notifier).refresh();
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
        title: Text('Calendário', style: AppTypography.titleLarge),
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
              if (_view == CalendarViewMode.week)
                CalendarWeekStrip(
                  selectedDay: _selectedDay,
                  onSelected: (DateTime day) =>
                      setState(() => _selectedDay = day),
                )
              else
                _monthGrid(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                PtDateLabels.longDate(_selectedDay),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // Pattern-matching, not `.when()` — same convention as
              // HomeScreen / DashboardScreen.
              switch (snapshotAsync) {
                AsyncData<CalendarDaySnapshot>(:final value) => CalendarDayList(
                    items: value.items,
                    onTap: (CalendarTaskItem item) => TaskDetailSheet.show(
                      context,
                      occurrenceId: item.occurrenceId,
                      title: item.title,
                    ),
                  ),
                AsyncError<CalendarDaySnapshot>() => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o calendário.',
                      onRetry: _refresh,
                    ),
                  ),
                _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppLoadingState(),
                  ),
              },
            ],
          ),
        ),
      ),
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
