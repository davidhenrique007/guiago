import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/performance/domain/level.dart';
import 'package:guiago/features/performance/domain/level_repository.dart';
import 'package:guiago/features/performance/domain/performance_record.dart';
import 'package:guiago/features/performance/domain/performance_record_repository.dart';
import 'package:guiago/features/performance/domain/score.dart';
import 'package:guiago/features/performance/domain/score_repository.dart';
import 'package:guiago/features/performance/domain/streak_repository.dart';
import 'package:guiago/features/performance/domain/streak_status.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_occurrence_repository.dart';

/// Simple in-memory fakes shared by the Performance and Dashboard
/// tests — no database, no mocking framework.
class InMemoryTaskOccurrenceRepository implements TaskOccurrenceRepository {
  final List<TaskOccurrence> items = <TaskOccurrence>[];

  /// When set, [getOccurrencesInRange] fails with it.
  Failure? rangeFailure;

  static bool _isLive(TaskOccurrence o) =>
      o.status == OccurrenceStatus.scheduled ||
      o.status == OccurrenceStatus.triggered ||
      o.status == OccurrenceStatus.snoozed;

  @override
  Future<Result<TaskOccurrence>> saveOccurrence(
    TaskOccurrence occurrence,
  ) async {
    items
      ..removeWhere((o) => o.id == occurrence.id)
      ..add(occurrence);
    return Success<TaskOccurrence>(occurrence);
  }

  @override
  Future<Result<TaskOccurrence?>> getOccurrence(String id) async {
    for (final TaskOccurrence o in items) {
      if (o.id == id) return Success<TaskOccurrence?>(o);
    }
    return const Success<TaskOccurrence?>(null);
  }

  @override
  Future<Result<List<TaskOccurrence>>> getOccurrencesForTask(
    String taskId,
  ) async {
    return Success<List<TaskOccurrence>>(
      items.where((o) => o.taskId == taskId).toList(),
    );
  }

  @override
  Future<Result<TaskOccurrence?>> getActiveOccurrenceForTask(
    String taskId,
  ) async {
    for (final TaskOccurrence o in items) {
      if (o.taskId == taskId && _isLive(o)) {
        return Success<TaskOccurrence?>(o);
      }
    }
    return const Success<TaskOccurrence?>(null);
  }

  @override
  Future<Result<List<TaskOccurrence>>> getAllActiveOccurrences() async {
    return Success<List<TaskOccurrence>>(items.where(_isLive).toList());
  }

  @override
  Future<Result<List<TaskOccurrence>>> getOccurrencesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final Failure? failure = rangeFailure;
    if (failure != null) return Fail<List<TaskOccurrence>>(failure);
    return Success<List<TaskOccurrence>>(
      items
          .where(
            (o) =>
                !o.scheduledAt.isBefore(start) && !o.scheduledAt.isAfter(end),
          )
          .toList(),
    );
  }
}

class InMemoryScoreRepository implements ScoreRepository {
  Score score = Score(total: 0, updatedAt: DateTime(2026));
  final List<ScoreEntry> entries = <ScoreEntry>[];

  @override
  Future<Result<Score>> getScore() async => Success<Score>(score);

  @override
  Future<Result<void>> saveScore(Score value) async {
    score = value;
    return const Success<void>(null);
  }

  @override
  Future<Result<ScoreEntry>> saveEntry(ScoreEntry entry) async {
    entries.add(entry);
    return Success<ScoreEntry>(entry);
  }

  @override
  Future<Result<List<ScoreEntry>>> getEntries() async {
    return Success<List<ScoreEntry>>(List<ScoreEntry>.of(entries));
  }
}

class InMemoryLevelRepository implements LevelRepository {
  final List<LevelStatus> items = <LevelStatus>[];

  @override
  Future<Result<LevelStatus>> saveEvaluation(LevelStatus status) async {
    items.add(status);
    return Success<LevelStatus>(status);
  }

  @override
  Future<Result<LevelStatus?>> getLatest() async {
    if (items.isEmpty) return const Success<LevelStatus?>(null);
    final LevelStatus latest = items.reduce(
      (a, b) => b.evaluatedAt.isBefore(a.evaluatedAt) ? a : b,
    );
    return Success<LevelStatus?>(latest);
  }

  @override
  Future<Result<List<LevelStatus>>> getHistory() async {
    return Success<List<LevelStatus>>(List<LevelStatus>.of(items));
  }
}

class InMemoryStreakRepository implements StreakRepository {
  StreakStatus? status;

  @override
  Future<Result<void>> saveStatus(StreakStatus value) async {
    status = value;
    return const Success<void>(null);
  }

  @override
  Future<Result<StreakStatus?>> getStatus() async {
    return Success<StreakStatus?>(status);
  }
}

class InMemoryPerformanceRecordRepository
    implements PerformanceRecordRepository {
  final List<PerformanceRecord> items = <PerformanceRecord>[];

  @override
  Future<Result<PerformanceRecord>> saveRecord(PerformanceRecord record) async {
    items.add(record);
    return Success<PerformanceRecord>(record);
  }

  @override
  Future<Result<List<PerformanceRecord>>> getRecordsInRange(
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    return Success<List<PerformanceRecord>>(
      items
          .where(
            (r) =>
                !r.periodStart.isBefore(periodStart) &&
                !r.periodEnd.isAfter(periodEnd),
          )
          .toList(),
    );
  }
}
