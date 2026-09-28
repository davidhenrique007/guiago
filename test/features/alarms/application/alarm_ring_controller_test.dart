import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/alarms/application/alarm_providers.dart';
import 'package:guiago/features/alarms/application/alarm_ring_controller.dart';
import 'package:guiago/features/alarms/domain/decline_reason.dart';
import 'package:guiago/features/alarms/domain/tts_speaker.dart';
import 'package:guiago/features/scheduler/data/scheduler_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';
import 'package:guiago/features/tasks/data/drift_task_occurrence_repository.dart';
import 'package:guiago/features/tasks/data/drift_task_repository.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';

class _FakeAlarmNotifier implements AlarmNotifier {
  final Set<int> scheduledIds = <int>{};

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    scheduledIds.add(id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancel(int id) async {
    scheduledIds.remove(id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancelAll() async {
    scheduledIds.clear();
    return const Success<void>(null);
  }

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

class _FakeTtsSpeaker implements TtsSpeaker {
  final List<String> spoken = <String>[];

  @override
  Future<Result<void>> speak(String text) async {
    spoken.add(text);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async => const Success<void>(null);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _FakeTtsSpeaker tts;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tts = _FakeTtsSpeaker();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(_FakeAlarmNotifier()),
        ttsServiceProvider.overrideWithValue(tts),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<String> seedOccurrence({
    String occurrenceId = 'occ-1',
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    int toleranceMinutes = 15,
  }) async {
    final DriftTaskRepository taskRepo = DriftTaskRepository(db);
    final DriftTaskOccurrenceRepository occRepo =
        DriftTaskOccurrenceRepository(db);
    await taskRepo.saveTask(
      Task(
        id: 'task-1',
        title: 'Beber água',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: toleranceMinutes,
        defaultSnoozeMinutes: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      ),
    );
    await occRepo.saveOccurrence(
      TaskOccurrence(
        id: occurrenceId,
        taskId: 'task-1',
        scheduledAt: DateTime.now(),
        status: status,
        snoozeCount: 0,
        toleranceMinutes: toleranceMinutes,
      ),
    );
    return occurrenceId;
  }

  group('AlarmRingController.build', () {
    test('triggers a SCHEDULED occurrence, loads the task, and speaks it',
        () async {
      final String occurrenceId = await seedOccurrence();

      final AlarmRingUiState state = await container.read(
        alarmRingControllerProvider(occurrenceId).future,
      );

      expect(state.task.title, 'Beber água');
      expect(state.occurrence.status, OccurrenceStatus.triggered);
      expect(state.isResolved, isFalse);
      expect(tts.spoken, contains('Beber água'));
    });

    test('loads an already-TRIGGERED occurrence without error', () async {
      final String occurrenceId = await seedOccurrence(
        occurrenceId: 'occ-already-triggered',
        status: OccurrenceStatus.triggered,
      );

      final AlarmRingUiState state = await container.read(
        alarmRingControllerProvider(occurrenceId).future,
      );

      expect(state.occurrence.status, OccurrenceStatus.triggered);
    });
  });

  group('AlarmRingController actions', () {
    test('complete() marks the occurrence completed and resolves the UI',
        () async {
      final String occurrenceId = await seedOccurrence();
      await container.read(alarmRingControllerProvider(occurrenceId).future);

      await container
          .read(alarmRingControllerProvider(occurrenceId).notifier)
          .complete();

      final AsyncValue<AlarmRingUiState> after =
          container.read(alarmRingControllerProvider(occurrenceId));
      final AlarmRingUiState? afterState = switch (after) {
        AsyncData<AlarmRingUiState>(:final value) => value,
        _ => null,
      };
      expect(afterState?.isResolved, isTrue);

      final occResult =
          await DriftTaskOccurrenceRepository(db).getOccurrence(occurrenceId);
      expect(occResult.valueOrNull?.status, OccurrenceStatus.completed);
    });

    test('decline() records the chosen reason', () async {
      final String occurrenceId = await seedOccurrence();
      await container.read(alarmRingControllerProvider(occurrenceId).future);

      await container
          .read(alarmRingControllerProvider(occurrenceId).notifier)
          .decline(DeclineReason.forgot);

      final occResult =
          await DriftTaskOccurrenceRepository(db).getOccurrence(occurrenceId);
      expect(occResult.valueOrNull?.status, OccurrenceStatus.declined);
      expect(occResult.valueOrNull?.declineReason, 'Esqueci');
    });

    test(
        'snooze() reschedules forward and still resolves the UI (closes the screen)',
        () async {
      final String occurrenceId = await seedOccurrence();
      await container.read(alarmRingControllerProvider(occurrenceId).future);

      await container
          .read(alarmRingControllerProvider(occurrenceId).notifier)
          .snooze();

      final AsyncValue<AlarmRingUiState> after =
          container.read(alarmRingControllerProvider(occurrenceId));
      final AlarmRingUiState? afterState = switch (after) {
        AsyncData<AlarmRingUiState>(:final value) => value,
        _ => null,
      };
      expect(afterState?.isResolved, isTrue);

      final occResult =
          await DriftTaskOccurrenceRepository(db).getOccurrence(occurrenceId);
      expect(occResult.valueOrNull?.status, OccurrenceStatus.scheduled);
      expect(occResult.valueOrNull?.snoozeCount, 1);
    });

    test(
        'zero-tolerance occurrence is auto-marked MISSED shortly after ringing',
        () async {
      final String occurrenceId = await seedOccurrence(toleranceMinutes: 0);

      await container.read(alarmRingControllerProvider(occurrenceId).future);
      // The miss happens on an un-awaited background call inside
      // build(); give it a moment to land before asserting.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final occResult =
          await DriftTaskOccurrenceRepository(db).getOccurrence(occurrenceId);
      expect(occResult.valueOrNull?.status, OccurrenceStatus.missed);
    });
  });
}
