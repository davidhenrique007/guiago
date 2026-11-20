import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../data/calendar_providers.dart';
import '../domain/calendar_month_snapshot.dart';
import 'calendar_controller.dart';

/// Loads the per-day task counts of one month. Family keyed by the
/// first day of the month (use [keyFor]).
class CalendarMonthController extends AsyncNotifier<CalendarMonthSnapshot> {
  CalendarMonthController(this.month);

  final DateTime month;

  static DateTime keyFor(DateTime value) => DateTime(value.year, value.month);

  @override
  Future<CalendarMonthSnapshot> build() async {
    final result = await ref.read(calendarServiceProvider).loadMonth(month);
    return switch (result) {
      Success<CalendarMonthSnapshot>(:final value) => value,
      Fail<CalendarMonthSnapshot>(:final failure) =>
        throw CalendarLoadException(failure),
    };
  }

  void refresh() => ref.invalidateSelf();
}

final calendarMonthControllerProvider = AsyncNotifierProvider.family<
    CalendarMonthController, CalendarMonthSnapshot, DateTime>(
  CalendarMonthController.new,
);
