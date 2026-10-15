import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tasks/domain/occurrence_status.dart';
import 'today_task_item.dart';

part 'home_snapshot.freezed.dart';

/// Everything the Home screen needs, already computed (master spec
/// §22: "Qual é a próxima coisa importante que preciso de fazer?").
/// The UI never computes this itself.
@freezed
sealed class HomeSnapshot with _$HomeSnapshot {
  const factory HomeSnapshot({
    required String userName,
    required DateTime today,
    required List<TodayTaskItem> todayTasks,

    /// The first not-yet-resolved item in [todayTasks] by
    /// scheduledAt, or null if everything today is resolved (or
    /// there's nothing scheduled).
    TodayTaskItem? nextTask,
  }) = _HomeSnapshot;

  const HomeSnapshot._();

  int get totalCount => todayTasks.length;

  int get completedCount =>
      todayTasks.where((t) => t.status == OccurrenceStatus.completed).length;

  bool get hasTasksToday => totalCount > 0;

  /// 0.0–1.0. 0 when nothing is scheduled today.
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}
