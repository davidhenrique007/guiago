import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/alarm_notifier.dart';

/// Thin wrapper around `flutter_local_notifications` — the only
/// place in the app that talks to the native notification/alarm
/// APIs (master spec §3: "O Scheduler deverá comunicar-se com os
/// mecanismos nativos da plataforma").
///
/// Timezone handling follows master spec §14: task times are local-
/// time concepts, so scheduling always goes through a
/// `tz.TZDateTime` built from the device's actual IANA timezone
/// (via `flutter_timezone`), never a bare UTC/`DateTime`. See
/// ADR-007.
class NotificationService implements AlarmNotifier {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'guiago_alarms';
  static const String _channelName = 'GuiaGo — Lembretes';
  static const String _channelDescription =
      'Lembretes de tarefas agendados pelo GuiaGo';

  Future<Result<void>> initialize() async {
    if (_initialized) return const Success<void>(null);

    try {
      tz_data.initializeTimeZones();

      final TimezoneInfo deviceTimezone =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(deviceTimezone.identifier),
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: settings,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);

      _initialized = true;

      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        PlatformFailure(
          'Failed to initialize notifications',
          cause: e,
        ),
      );
    }
  }

  /// Requests notification + exact-alarm permissions. Call this from
  /// onboarding or first task creation — never silently.
  Future<Result<bool>> requestPermissions() async {
    try {
      final PermissionStatus notificationStatus =
          await Permission.notification.request();

      final PermissionStatus exactAlarmStatus =
          await Permission.scheduleExactAlarm.request();

      return Success<bool>(
        notificationStatus.isGranted && exactAlarmStatus.isGranted,
      );
    } catch (e) {
      return Fail<bool>(
        PermissionFailure(
          'Failed to request notification permissions',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    try {
      await _ensureInitialized();

      final tz.TZDateTime scheduled = tz.TZDateTime.from(scheduledAt, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        AlarmFailure(
          'Failed to schedule alarm',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);

      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        AlarmFailure(
          'Failed to cancel alarm',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancelAll() async {
    try {
      await _plugin.cancelAll();

      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        AlarmFailure(
          'Failed to cancel all alarms',
          cause: e,
        ),
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
