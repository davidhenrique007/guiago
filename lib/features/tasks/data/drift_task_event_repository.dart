import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/occurrence_status.dart';
import '../domain/task_event.dart';
import '../domain/task_event_repository.dart';

class DriftTaskEventRepository implements TaskEventRepository {
  DriftTaskEventRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<void>> recordEvent(TaskEvent event) async {
    try {
      await _db.into(_db.taskEventsTable).insert(
            TaskEventsTableCompanion.insert(
              id: event.id,
              taskId: event.taskId,
              occurrenceId: event.occurrenceId,
              fromStatus: event.fromStatus.name,
              toStatus: event.toStatus.name,
              occurredAt: event.occurredAt,
              note: Value<String?>(event.note),
            ),
          );
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        DatabaseFailure('Failed to record task event', cause: e),
      );
    }
  }

  @override
  Future<Result<List<TaskEvent>>> getEventsForOccurrence(
    String occurrenceId,
  ) async {
    try {
      final List<TaskEventRow> rows = await (_db.select(_db.taskEventsTable)
            ..where((e) => e.occurrenceId.equals(occurrenceId))
            ..orderBy([(e) => OrderingTerm.asc(e.occurredAt)]))
          .get();
      return Success<List<TaskEvent>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<TaskEvent>>(
        DatabaseFailure('Failed to load task events', cause: e),
      );
    }
  }

  TaskEvent _toDomain(TaskEventRow row) => TaskEvent(
        id: row.id,
        taskId: row.taskId,
        occurrenceId: row.occurrenceId,
        fromStatus: OccurrenceStatus.values.byName(row.fromStatus),
        toStatus: OccurrenceStatus.values.byName(row.toStatus),
        occurredAt: row.occurredAt,
        note: row.note,
      );
}
