import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../tasks/application/task_engine.dart';
import '../../tasks/data/task_providers.dart';
import '../application/scheduler_engine.dart';
import '../domain/alarm_notifier.dart';
import '../domain/alarm_repository.dart';
import '../infrastructure/notification_service.dart';
import 'drift_alarm_repository.dart';

final Provider<AlarmNotifier> notificationServiceProvider =
    Provider<AlarmNotifier>((ref) => NotificationService());

final Provider<AlarmRepository> alarmRepositoryProvider =
    Provider<AlarmRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftAlarmRepository(db);
});

final Provider<SchedulerEngine> schedulerEngineProvider =
    Provider<SchedulerEngine>((ref) {
  return SchedulerEngine(
    notificationService: ref.watch(notificationServiceProvider),
    alarmRepository: ref.watch(alarmRepositoryProvider),
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

/// A [TaskEngine] with alarm scheduling wired in. Prefer this over
/// the plain `taskEngineProvider` (from `tasks/data/task_providers.dart`)
/// once alarms matter — that one stays scheduler-free on purpose, so
/// the tasks feature never has to import the scheduler feature (see
/// ADR-006).
final Provider<TaskEngine> taskEngineWithSchedulerProvider =
    Provider<TaskEngine>((ref) {
  return TaskEngine(
    taskRepository: ref.watch(taskRepositoryProvider),
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    eventRepository: ref.watch(taskEventRepositoryProvider),
    alarmScheduler: ref.watch(schedulerEngineProvider),
  );
});
