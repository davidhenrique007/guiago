import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../tasks/data/task_providers.dart';
import '../application/scheduler_engine.dart';
import '../domain/alarm_record_repository.dart';
import '../domain/alarm_scheduler.dart';
import '../domain/permission_service.dart';
import '../infrastructure/notification_alarm_scheduler.dart';
import '../infrastructure/permission_handler_service.dart';
import 'drift_alarm_record_repository.dart';

/// Single shared plugin instance for the app's lifetime — mirrors
/// `appDatabaseProvider`'s pattern in `core/services`.
final Provider<FlutterLocalNotificationsPlugin>
    flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final Provider<AlarmRecordRepository> alarmRecordRepositoryProvider =
    Provider<AlarmRecordRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftAlarmRecordRepository(db);
});

final Provider<AlarmScheduler> alarmSchedulerProvider =
    Provider<AlarmScheduler>((ref) {
  final FlutterLocalNotificationsPlugin plugin =
      ref.watch(flutterLocalNotificationsPluginProvider);
  return NotificationAlarmScheduler(plugin);
});

final Provider<PermissionService> permissionServiceProvider =
    Provider<PermissionService>((ref) {
  return PermissionHandlerService();
});

final Provider<SchedulerEngine> schedulerEngineProvider =
    Provider<SchedulerEngine>((ref) {
  return SchedulerEngine(
    alarmRepository: ref.watch(alarmRecordRepositoryProvider),
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    alarmScheduler: ref.watch(alarmSchedulerProvider),
    permissionService: ref.watch(permissionServiceProvider),
  );
});
