import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/occurrence_status.dart';
import '../domain/task_occurrence.dart';
import '../domain/task_occurrence_repository.dart';

class DriftTaskOccurrenceRepository implements TaskOccurrenceRepository {
  DriftTaskOccurrenceRepository(this._db);

  final AppDatabase _db;

  static const List<OccurrenceStatus> _liveStatuses = <OccurrenceStatus>[
    OccurrenceStatus.scheduled,
    OccurrenceStatus.triggered,
    OccurrenceStatus.snoozed,
  ];

  @override
  Future<Result<TaskOccurrence>> saveOccurrence(
    TaskOccurrence occurrence,
  ) async {
    try {
      await _db.into(_db.taskOccurrencesTable).insertOnConflictUpdate(
            TaskOccurrencesTableCompanion.insert(
              id: occurrence.id,
              taskId: occurrence.taskId,
              scheduledAt: occurrence.scheduledAt,
              triggeredAt: Value<DateTime?>(occurrence.triggeredAt),
              completedAt: Value<DateTime?>(occurrence.completedAt),
              status: occurrence.status.name,
              snoozeCount: Value<int>(occurrence.snoozeCount),
              responseTimeSeconds:
                  Value<int?>(occurrence.responseTime?.inSeconds),
              toleranceMinutes: occurrence.toleranceMinutes,
              declineReason: Value<String?>(occurrence.declineReason),
            ),
          );
      return Success<TaskOccurrence>(occurrence);
    } catch (e) {
      return Fail<TaskOccurrence>(
        DatabaseFailure('Failed to save occurrence', cause: e),
      );
    }
  }

  @override
  Future<Result<TaskOccurrence?>> getOccurrence(String id) async {
    try {
      final TaskOccurrenceRow? row = await (_db.select(_db.taskOccurrencesTable)
            ..where((o) => o.id.equals(id)))
          .getSingleOrNull();
      return Success<TaskOccurrence?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<TaskOccurrence?>(
        DatabaseFailure('Failed to load occurrence', cause: e),
      );
    }
  }

  @override
  Future<Result<List<TaskOccurrence>>> getOccurrencesForTask(
    String taskId,
  ) async {
    try {
      final List<TaskOccurrenceRow> rows =
          await (_db.select(_db.taskOccurrencesTable)
                ..where((o) => o.taskId.equals(taskId))
                ..orderBy([(o) => OrderingTerm.desc(o.scheduledAt)]))
              .get();
      return Success<List<TaskOccurrence>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<TaskOccurrence>>(
        DatabaseFailure('Failed to load occurrences', cause: e),
      );
    }
  }

  @override
  Future<Result<TaskOccurrence?>> getActiveOccurrenceForTask(
    String taskId,
  ) async {
    try {
      final List<String> liveNames =
          _liveStatuses.map((OccurrenceStatus s) => s.name).toList();
      final TaskOccurrenceRow? row = await (_db.select(_db.taskOccurrencesTable)
            ..where(
              (o) => o.taskId.equals(taskId) & o.status.isIn(liveNames),
            )
            ..orderBy([(o) => OrderingTerm.desc(o.scheduledAt)])
            ..limit(1))
          .getSingleOrNull();
      return Success<TaskOccurrence?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<TaskOccurrence?>(
        DatabaseFailure('Failed to load active occurrence', cause: e),
      );
    }
  }

  TaskOccurrence _toDomain(TaskOccurrenceRow row) => TaskOccurrence(
        id: row.id,
        taskId: row.taskId,
        scheduledAt: row.scheduledAt,
        triggeredAt: row.triggeredAt,
        completedAt: row.completedAt,
        status: OccurrenceStatus.values.byName(row.status),
        snoozeCount: row.snoozeCount,
        responseTime: row.responseTimeSeconds == null
            ? null
            : Duration(seconds: row.responseTimeSeconds!),
        toleranceMinutes: row.toleranceMinutes,
        declineReason: row.declineReason,
      );
}
