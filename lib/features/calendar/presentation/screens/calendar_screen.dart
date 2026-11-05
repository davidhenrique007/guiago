import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
import '../../application/calendar_controller.dart';
import '../../domain/calendar_day_snapshot.dart';
import '../widgets/calendar_day_list.dart';
import '../widgets/calendar_week_strip.dart';

/// The Calendar tab: a Monday-to-Sunday strip and the occurrences of
/// the selected day. Purely a view over [CalendarController].
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay = CalendarController.keyFor(DateTime.now());

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Nova tarefa',
        onPressed: () async {
          await context.pushNamed(AppRoutes.taskCreateName);
          // The new task may fall on the day being shown — reload.
          ref.read(calendarControllerProvider(_selectedDay).notifier).refresh();
        },
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(calendarControllerProvider(_selectedDay).notifier).refresh();
            await ref.read(calendarControllerProvider(_selectedDay).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              CalendarWeekStrip(
                selectedDay: _selectedDay,
                onSelected: (DateTime day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                PtDateLabels.longDate(_selectedDay),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // Pattern-matching, not `.when()` — same convention as
              // HomeScreen / DashboardScreen.
              switch (snapshotAsync) {
                AsyncData<CalendarDaySnapshot>(:final value) =>
                  CalendarDayList(items: value.items),
                AsyncError<CalendarDaySnapshot>() => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o calendário.',
                      onRetry: () => ref
                          .read(
                            calendarControllerProvider(_selectedDay).notifier,
                          )
                          .refresh(),
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
}
