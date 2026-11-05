/// Every number the Insights feature depends on, in one place (same
/// spirit as `ScoringPolicy` / `LevelPolicy`: never scatter them).
class InsightsPolicy {
  const InsightsPolicy({
    this.minCompletions = 10,
    this.peakWindowHours = 3,
    this.topTasksCount = 3,
  });

  /// Below this many completions in the period no productivity peak is
  /// shown — a peak from a handful of data points would be invented.
  final int minCompletions;

  /// Length, in consecutive hours, of the highlighted peak window.
  final int peakWindowHours;

  /// How many tasks the "Tarefas mais concluídas" card lists.
  final int topTasksCount;

  static const InsightsPolicy defaultPolicy = InsightsPolicy();
}
