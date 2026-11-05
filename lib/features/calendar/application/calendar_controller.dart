import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/calendar_providers.dart';
import '../domain/calendar_day_snapshot.dart';

/// Thrown into the [AsyncValue] when a day cannot be loaded, so the
/// UI can show the original [failure] in an error state.
class CalendarLoadException implements Exception {
  const CalendarLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'CalendarLoadException: ${failure.message}';
}

/// One controller per day (Riverpod family; the argument arrives via
/// the constructor, like `DashboardController`). The key must be the
/// day normalised to local midnight — see [CalendarController.keyFor].
class CalendarController extends AsyncNotifier<CalendarDaySnapshot> {
  CalendarController(this.day);

  final DateTime day;

  /// Normalises any date-time to local midnight, the family key.
  static DateTime keyFor(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Future<CalendarDaySnapshot> build() async {
    final Result<CalendarDaySnapshot> result =
        await ref.read(calendarServiceProvider).load(day);
    return switch (result) {
      Success<CalendarDaySnapshot>(:final value) => value,
      Fail<CalendarDaySnapshot>(:final failure) =>
        throw CalendarLoadException(failure),
    };
  }

  /// Re-reads the day (pull-to-refresh, or after creating a task).
  void refresh() => ref.invalidateSelf();
}

final calendarControllerProvider = AsyncNotifierProvider.family<
    CalendarController, CalendarDaySnapshot, DateTime>(
  CalendarController.new,
);
