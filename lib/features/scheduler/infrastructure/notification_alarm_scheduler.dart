import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/alarm_scheduler.dart';
import 'timezone_service.dart';

/// [AlarmScheduler] backed by `flutter_local_notifications` (master
/// spec §3 Fase 3, §13).
///
/// `initialize`, `zonedSchedule`, and `cancel` all take fully-named
/// parameters in the pinned `^22.3.0` — confirmed against this
/// project's own `flutter analyze` output (pub.dev was outside my
/// sandbox's network access, so this was verified from the compiler
/// error, not the changelog).
class NotificationAlarmScheduler implements AlarmScheduler {
  NotificationAlarmScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'guiago_alarms';
  static const String _channelName = 'Alarmes GuiaGo';
  static const String _channelDescription =
      'Alarmes de tarefas agendadas no GuiaGo';

  @override
  Future<Result<void>> initialize() async {
    if (_initialized) return const Success<void>(null);
    try {
      await TimezoneService.ensureInitialized();

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(settings: initSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        PlatformFailure('Failed to initialize notification plugin', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> scheduleAlarm({
    required int nativeAlarmId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String payload,
  }) async {
    final Result<void> initResult = await initialize();
    if (initResult case Fail<void>(:final failure)) {
      return Fail<void>(failure);
    }

    try {
      final tz.TZDateTime scheduledTZ =
          TimezoneService.toLocalTZDateTime(scheduledAt);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: nativeAlarmId,
        title: title,
        body: body,
        scheduledDate: scheduledTZ,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        AlarmFailure('Failed to schedule alarm $nativeAlarmId', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> cancelAlarm(int nativeAlarmId) async {
    try {
      await _plugin.cancel(id: nativeAlarmId);
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        AlarmFailure('Failed to cancel alarm $nativeAlarmId', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> cancelAll() async {
    try {
      await _plugin.cancelAll();
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(AlarmFailure('Failed to cancel all alarms', cause: e));
    }
  }
}
