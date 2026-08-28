import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/scheduler/application/scheduler_engine.dart';
import 'package:guiago/features/scheduler/domain/alarm_record.dart';
import 'package:guiago/features/scheduler/domain/alarm_record_repository.dart';
import 'package:guiago/features/scheduler/domain/alarm_scheduler.dart';
import 'package:guiago/features/scheduler/domain/alarm_status.dart';
import 'package:guiago/features/scheduler/domain/permission_service.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';
import 'package:guiago/features/tasks/domain/recurrence_rule.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_occurrence.dart';
import 'package:guiago/features/tasks/domain/task_occurrence_repository.dart';
import 'package:guiago/features/tasks/domain/task_priority.dart';
import 'package:guiago/features/tasks/domain/task_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAlarmRecordRepository extends Mock implements AlarmRecordRepository {}

class MockTaskOccurrenceRepository extends Mock
    implements TaskOccurrenceRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockAlarmScheduler extends Mock implements AlarmScheduler {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockAlarmRecordRepository alarmRepository;
  late MockTaskOccurrenceRepository occurrenceRepository;
  late MockTaskRepository taskRepository;
  late MockAlarmScheduler alarmScheduler;
  late MockPermissionService permissionService;
  late SchedulerEngine engine;

  final Task task = Task(
    id: 'task-1',
    title: 'Estudar Flutter',
    priority: TaskPriority.medium,
    recurrenceRule: const RecurrenceRule.none(),
    defaultToleranceMinutes: 15,
    defaultSnoozeMinutes: 10,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    isArchived: false,
  );

  final TaskOccurrence occurrence = TaskOccurrence(
    id: 'occurrence-1',
    taskId: 'task-1',
    scheduledAt: DateTime(2026, 1, 2, 9),
    status: OccurrenceStatus.scheduled,
    snoozeCount: 0,
    toleranceMinutes: 15,
  );

  setUpAll(() {
    // mocktail needs a fallback instance for any() on a custom
    // (non-built-in) type — AlarmRecord is used with any() in
    // `alarmRepository.saveAlarmRecord(any())` below.
    registerFallbackValue(
      AlarmRecord(
        id: 'fallback',
        occurrenceId: 'fallback',
        taskId: 'fallback',
        nativeAlarmId: 0,
        scheduledAt: DateTime(2026),
        status: AlarmStatus.scheduled,
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    alarmRepository = MockAlarmRecordRepository();
    occurrenceRepository = MockTaskOccurrenceRepository();
    taskRepository = MockTaskRepository();
    alarmScheduler = MockAlarmScheduler();
    permissionService = MockPermissionService();
    engine = SchedulerEngine(
      alarmRepository: alarmRepository,
      occurrenceRepository: occurrenceRepository,
      taskRepository: taskRepository,
      alarmScheduler: alarmScheduler,
      permissionService: permissionService,
    );

    // Sensible defaults; individual tests override as needed.
    when(() => permissionService.ensureNotificationPermission())
        .thenAnswer((_) async => const Success<bool>(true));
    when(() => permissionService.ensureExactAlarmPermission())
        .thenAnswer((_) async => const Success<bool>(true));
    when(() => taskRepository.getTask('task-1'))
        .thenAnswer((_) async => Success<Task?>(task));
    when(() => alarmRepository.getActiveAlarmForOccurrence(any()))
        .thenAnswer((_) async => const Success<AlarmRecord?>(null));
    when(() => alarmRepository.nativeAlarmIdInUse(any()))
        .thenAnswer((_) async => const Success<bool>(false));
    when(
      () => alarmScheduler.scheduleAlarm(
        nativeAlarmId: any(named: 'nativeAlarmId'),
        scheduledAt: any(named: 'scheduledAt'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => const Success<void>(null));
    when(() => alarmScheduler.cancelAlarm(any()))
        .thenAnswer((_) async => const Success<void>(null));
    when(() => alarmRepository.saveAlarmRecord(any()))
        .thenAnswer((Invocation inv) async {
      return Success<AlarmRecord>(
        inv.positionalArguments.first as AlarmRecord,
      );
    });
  });

  group('scheduleForOccurrence', () {
    test('arms the native alarm and persists a scheduled AlarmRecord',
        () async {
      final Result<AlarmRecord> result =
          await engine.scheduleForOccurrence(occurrence);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.status, AlarmStatus.scheduled);
      expect(result.valueOrNull?.occurrenceId, occurrence.id);
      verify(
        () => alarmScheduler.scheduleAlarm(
          nativeAlarmId: any(named: 'nativeAlarmId'),
          scheduledAt: occurrence.scheduledAt,
          title: task.title,
          body: any(named: 'body'),
          payload: occurrence.id,
        ),
      ).called(1);
    });

    test('fails with PermissionFailure when notification permission denied',
        () async {
      when(() => permissionService.ensureNotificationPermission())
          .thenAnswer((_) async => const Success<bool>(false));

      final Result<AlarmRecord> result =
          await engine.scheduleForOccurrence(occurrence);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
      verifyNever(
        () => alarmScheduler.scheduleAlarm(
          nativeAlarmId: any(named: 'nativeAlarmId'),
          scheduledAt: any(named: 'scheduledAt'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('cancels any existing live alarm for the occurrence first',
        () async {
      final AlarmRecord existing = AlarmRecord(
        id: 'alarm-old',
        occurrenceId: occurrence.id,
        taskId: task.id,
        nativeAlarmId: 42,
        scheduledAt: occurrence.scheduledAt,
        status: AlarmStatus.scheduled,
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => alarmRepository.getActiveAlarmForOccurrence(occurrence.id))
          .thenAnswer((_) async => Success<AlarmRecord?>(existing));

      await engine.scheduleForOccurrence(occurrence);

      verify(() => alarmScheduler.cancelAlarm(42)).called(1);
    });
  });

  group('cancelForOccurrence', () {
    test('is a no-op success when there is no live alarm', () async {
      final Result<void> result =
          await engine.cancelForOccurrence(occurrence.id);

      expect(result.isSuccess, isTrue);
      verifyNever(() => alarmScheduler.cancelAlarm(any()));
    });
  });

  group('rescheduleAll', () {
    test('reschedules every active task\'s live occurrence', () async {
      when(() => taskRepository.getActiveTasks())
          .thenAnswer((_) async => Success<List<Task>>(<Task>[task]));
      when(() => occurrenceRepository.getActiveOccurrenceForTask('task-1'))
          .thenAnswer((_) async => Success<TaskOccurrence?>(occurrence));

      final Result<int> result = await engine.rescheduleAll();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 1);
    });

    test('skips tasks with no live occurrence', () async {
      when(() => taskRepository.getActiveTasks())
          .thenAnswer((_) async => Success<List<Task>>(<Task>[task]));
      when(() => occurrenceRepository.getActiveOccurrenceForTask('task-1'))
          .thenAnswer((_) async => const Success<TaskOccurrence?>(null));

      final Result<int> result = await engine.rescheduleAll();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 0);
    });
  });
}
