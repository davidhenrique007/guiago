import 'package:freezed_annotation/freezed_annotation.dart';

import 'calendar_task_item.dart';

part 'calendar_day_snapshot.freezed.dart';

/// Everything the Calendar screen shows for one day.
@freezed
sealed class CalendarDaySnapshot with _$CalendarDaySnapshot {
  const factory CalendarDaySnapshot({
    /// The day, normalised to local midnight.
    required DateTime day,

    /// Occurrences of [day], ordered by `scheduledAt`.
    required List<CalendarTaskItem> items,
  }) = _CalendarDaySnapshot;
}
