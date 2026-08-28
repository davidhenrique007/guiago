import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence_rule.freezed.dart';

/// How a [Task] repeats (master spec §12).
///
/// `weekly` repeats on the same weekday as the task's original
/// anchor date. `customDays` repeats on an explicit set of weekdays
/// (1 = Monday .. 7 = Sunday, matching `DateTime.weekday`) —
/// deliberately separate from `weekly` since a "weekly" task doesn't
/// require the user to pick a day (it's implied by the anchor),
/// while `customDays` always does.
@freezed
sealed class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule.none() = RecurrenceNone;
  const factory RecurrenceRule.daily() = RecurrenceDaily;
  const factory RecurrenceRule.weekly() = RecurrenceWeekly;
  const factory RecurrenceRule.customDays({required Set<int> weekdays}) =
      RecurrenceCustomDays;
}
