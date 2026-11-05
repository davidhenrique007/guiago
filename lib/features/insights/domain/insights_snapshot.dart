import 'package:freezed_annotation/freezed_annotation.dart';

part 'insights_snapshot.freezed.dart';

/// The most productive stretch of the day: [startHour] up to and
/// including [endHour] (local time, 0–23), e.g. 8 and 10 for
/// "08:00 – 11:00".
@freezed
sealed class ProductivityPeak with _$ProductivityPeak {
  const factory ProductivityPeak({
    required int startHour,
    required int endHour,
  }) = _ProductivityPeak;
}

/// One row of "Tarefas mais concluídas".
@freezed
sealed class TopTaskItem with _$TopTaskItem {
  const factory TopTaskItem({
    required String taskId,
    required String title,
    required int completedCount,
  }) = _TopTaskItem;
}

/// What the Insights screen shows besides the summary (which comes
/// from the dashboard's month snapshot).
@freezed
sealed class InsightsSnapshot with _$InsightsSnapshot {
  const factory InsightsSnapshot({
    /// Completions per local hour of the day; always 24 entries.
    required List<int> completionsByHour,
    required int totalCompletions,

    /// Null when there are fewer completions than
    /// `InsightsPolicy.minCompletions`.
    ProductivityPeak? peak,

    /// At most `InsightsPolicy.topTasksCount`, most completed first.
    required List<TopTaskItem> topTasks,
  }) = _InsightsSnapshot;
}
