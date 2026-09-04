import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late DriftTaskOccurrenceRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTaskOccurrenceRepository(db);

    // Occurrences reference a task via a foreign key, so seed one.
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
  });

  tearDown(() => db.close());

  TaskOccurrence buildOccurrence({
    String id = 'occ-1',
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    DateTime? scheduledAt,
  }) {
    return TaskOccurrence(
      id: id,
      taskId: 'task-1',
      scheduledAt: scheduledAt ?? DateTime(2026, 8, 24, 9, 0),
      status: status,
      snoozeCount: 0,
      toleranceMinutes: 15,
    );
  }

  group('DriftTaskOccurrenceRepository', () {
    test('saveOccurrence then getOccurrence round-trips all fields', () async {
      final TaskOccurrence occurrence = buildOccurrence().copyWith(
        triggeredAt: DateTime(2026, 8, 24, 9, 1),
        responseTime: const Duration(seconds: 42),
        declineReason: null,
      );
      await repository.saveOccurrence(occurrence);

      final result = await repository.getOccurrence(occurrence.id);
      expect(result.valueOrNull, occurrence);
    });

    test('getOccurrencesForTask returns all occurrences, newest first',
        () async {
      await repository.saveOccurrence(
        buildOccurrence(id: 'occ-1', scheduledAt: DateTime(2026, 8, 24, 9, 0)),
      );
      await repository.saveOccurrence(
        buildOccurrence(id: 'occ-2', scheduledAt: DateTime(2026, 8, 25, 9, 0)),
      );

      final result = await repository.getOccurrencesForTask('task-1');
      final ids = result.valueOrNull!.map((o) => o.id).toList();
      expect(ids, <String>['occ-2', 'occ-1']);
    });

    test(
      'getActiveOccurrenceForTask finds a live (non-terminal) occurrence',
      () async {
        await repository.saveOccurrence(
          buildOccurrence(status: OccurrenceStatus.scheduled),
        );

        final result = await repository.getActiveOccurrenceForTask('task-1');
        expect(result.valueOrNull?.status, OccurrenceStatus.scheduled);
      },
    );

    test(
      'getActiveOccurrenceForTask returns null once the occurrence is terminal',
      () async {
        await repository.saveOccurrence(
          buildOccurrence(status: OccurrenceStatus.completed),
        );

        final result = await repository.getActiveOccurrenceForTask('task-1');
        expect(result.valueOrNull, isNull);
      },
    );

    test(
      'getAllActiveOccurrences returns live occurrences across every task, oldest first',
      () async {
        await repository.saveOccurrence(
          buildOccurrence(
            id: 'occ-later',
            scheduledAt: DateTime(2026, 8, 25, 9, 0),
          ),
        );
        await repository.saveOccurrence(
          buildOccurrence(
            id: 'occ-earlier',
            scheduledAt: DateTime(2026, 8, 24, 9, 0),
          ),
        );
        await repository.saveOccurrence(
          buildOccurrence(id: 'occ-done', status: OccurrenceStatus.completed),
        );

        final result = await repository.getAllActiveOccurrences();

        final ids = result.valueOrNull!.map((o) => o.id).toList();
        expect(ids, <String>['occ-earlier', 'occ-later']);
      },
    );
  });
}
