import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/alarms/application/alarm_providers.dart';
import 'package:guiago/features/alarms/application/alarm_ring_controller.dart';
import 'package:guiago/features/alarms/domain/tts_speaker.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
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
  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> cancel(int id) async => const Success<void>(null);

  @override
  Future<Result<void>> cancelAll() async => const Success<void>(null);

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

  Future<void> seed() async {
    await DriftTaskRepository(db).saveTask(
      Task(
        id: 'task-1',
        title: 'Beber água',
        priority: TaskPriority.low,
        recurrenceRule: const RecurrenceRule.none(),
        defaultToleranceMinutes: 15,
        defaultSnoozeMinutes: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      ),
    );
    await DriftTaskOccurrenceRepository(db).saveOccurrence(
      TaskOccurrence(
        id: 'occ-1',
        taskId: 'task-1',
        scheduledAt: DateTime.now(),
        status: OccurrenceStatus.scheduled,
        snoozeCount: 0,
        toleranceMinutes: 15,
      ),
    );
  }

  test('does not speak when voice reading is switched off', () async {
    await seed();
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(ttsEnabled: false),
    );

    await container.read(alarmRingControllerProvider('occ-1').future);

    expect(tts.spoken, isEmpty);
  });

  test('speaks when voice reading is on', () async {
    await seed();
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(ttsEnabled: true),
    );

    await container.read(alarmRingControllerProvider('occ-1').future);

    expect(tts.spoken, <String>['Beber água']);
  });
}
