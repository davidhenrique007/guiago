import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../data/calendar_providers.dart';
import '../domain/calendar_year_snapshot.dart';
import 'calendar_controller.dart';

/// Loads the per-month task counts of one year. Family keyed by the
/// year number.
class CalendarYearController extends AsyncNotifier<CalendarYearSnapshot> {
  CalendarYearController(this.year);

  final int year;

  @override
  Future<CalendarYearSnapshot> build() async {
    final result = await ref.read(calendarServiceProvider).loadYear(year);
    return switch (result) {
      Success<CalendarYearSnapshot>(:final value) => value,
      Fail<CalendarYearSnapshot>(:final failure) =>
        throw CalendarLoadException(failure),
    };
  }

  void refresh() => ref.invalidateSelf();
}

final calendarYearControllerProvider = AsyncNotifierProvider.family<
    CalendarYearController, CalendarYearSnapshot, int>(
  CalendarYearController.new,
);
