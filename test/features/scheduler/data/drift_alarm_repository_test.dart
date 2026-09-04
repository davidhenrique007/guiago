import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/scheduler/data/drift_alarm_repository.dart';
import 'package:guiago/features/scheduler/domain/alarm_record.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late DriftAlarmRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAlarmRepository(db);

    // Alarm records reference a task and an occurrence via foreign
    // keys, so seed both.
    final DateTime now = DateTime(2026, 8, 24, 9, 0);
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 'task-1',
        title: 'Estudar Flutter',
        priority: TaskPriority.medium,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: now,
        updatedAt: now,
        isArchived: false,
      ),
    );
    await DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: 'occ-1',
        taskId: 'task-1',
        scheduledAt: now,
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  });

  tearDown(() => db.close());

  AlarmRecord buildRecord({String occurrenceId = 'occ-1'}) => AlarmRecord(
        occurrenceId: occurrenceId,
        taskId: 'task-1',
        nativeAlarmId: 42,
        scheduledAt: DateTime(2026, 8, 24, 9, 0),
        createdAt: DateTime(2026, 8, 24, 8, 0),
      );

  group('DriftAlarmRepository', () {
    test('saveAlarmRecord then getAlarmRecord round-trips it', () async {
      final AlarmRecord record = buildRecord();
      final saveResult = await repository.saveAlarmRecord(record);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repository.getAlarmRecord('occ-1');
      expect(getResult.valueOrNull, record);
    });

    test('getAlarmRecord returns null when none exists', () async {
      final result = await repository.getAlarmRecord('does-not-exist');
      expect(result.valueOrNull, isNull);
    });

    test('saving twice for the same occurrence overwrites, not duplicates',
        () async {
      await repository.saveAlarmRecord(buildRecord());
      final AlarmRecord updated = buildRecord().copyWith(nativeAlarmId: 99);
      await repository.saveAlarmRecord(updated);

      final result = await repository.getAlarmRecord('occ-1');
      expect(result.valueOrNull?.nativeAlarmId, 99);

      final allResult = await repository.getAllAlarmRecords();
      expect(allResult.valueOrNull, hasLength(1));
    });

    test('deleteAlarmRecord removes it', () async {
      await repository.saveAlarmRecord(buildRecord());

      await repository.deleteAlarmRecord('occ-1');

      final result = await repository.getAlarmRecord('occ-1');
      expect(result.valueOrNull, isNull);
    });
  });
}
