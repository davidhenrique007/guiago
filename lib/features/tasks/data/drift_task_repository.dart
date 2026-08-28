import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';
import '../domain/task_repository.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<Task>> saveTask(Task task) async {
    try {
      await _db.into(_db.tasksTable).insertOnConflictUpdate(
            TasksTableCompanion.insert(
              id: task.id,
              title: task.title,
              description: Value<String?>(task.description),
              priority: task.priority.name,
              recurrenceType: _recurrenceTypeOf(task.recurrenceRule),
              recurrenceWeekdays:
                  Value<String?>(_recurrenceWeekdaysOf(task.recurrenceRule)),
              defaultToleranceMinutes: task.defaultToleranceMinutes,
              defaultSnoozeMinutes: task.defaultSnoozeMinutes,
              createdAt: task.createdAt,
              updatedAt: task.updatedAt,
              isArchived: Value<bool>(task.isArchived),
            ),
          );
      return Success<Task>(task);
    } catch (e) {
      return Fail<Task>(DatabaseFailure('Failed to save task', cause: e));
    }
  }

  @override
  Future<Result<Task?>> getTask(String id) async {
    try {
      final TaskRow? row = await (_db.select(_db.tasksTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return Success<Task?>(row == null ? null : _toDomain(row));
    } catch (e) {
      return Fail<Task?>(DatabaseFailure('Failed to load task', cause: e));
    }
  }

  @override
  Future<Result<List<Task>>> getActiveTasks() async {
    try {
      final List<TaskRow> rows = await (_db.select(_db.tasksTable)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
      return Success<List<Task>>(rows.map(_toDomain).toList());
    } catch (e) {
      return Fail<List<Task>>(
        DatabaseFailure('Failed to load tasks', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> archiveTask(String id) async {
    try {
      await (_db.update(_db.tasksTable)..where((t) => t.id.equals(id)))
          .write(const TasksTableCompanion(isArchived: Value<bool>(true)));
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(DatabaseFailure('Failed to archive task', cause: e));
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      await (_db.delete(_db.tasksTable)..where((t) => t.id.equals(id))).go();
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(DatabaseFailure('Failed to delete task', cause: e));
    }
  }

  Task _toDomain(TaskRow row) => Task(
        id: row.id,
        title: row.title,
        description: row.description,
        priority: TaskPriority.values.byName(row.priority),
        recurrenceRule:
            _recurrenceRuleFrom(row.recurrenceType, row.recurrenceWeekdays),
        defaultToleranceMinutes: row.defaultToleranceMinutes,
        defaultSnoozeMinutes: row.defaultSnoozeMinutes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isArchived: row.isArchived,
      );

  static String _recurrenceTypeOf(RecurrenceRule rule) => switch (rule) {
        RecurrenceNone() => 'none',
        RecurrenceDaily() => 'daily',
        RecurrenceWeekly() => 'weekly',
        RecurrenceCustomDays() => 'customDays',
      };

  static String? _recurrenceWeekdaysOf(RecurrenceRule rule) => switch (rule) {
        RecurrenceCustomDays(:final weekdays) =>
          (weekdays.toList()..sort()).join(','),
        _ => null,
      };

  static RecurrenceRule _recurrenceRuleFrom(
    String type,
    String? weekdaysCsv,
  ) =>
      switch (type) {
        'daily' => const RecurrenceRule.daily(),
        'weekly' => const RecurrenceRule.weekly(),
        'customDays' => RecurrenceRule.customDays(
            weekdays: (weekdaysCsv ?? '')
                .split(',')
                .where((String s) => s.isNotEmpty)
                .map(int.parse)
                .toSet(),
          ),
        _ => const RecurrenceRule.none(),
      };
}
