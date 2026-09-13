import 'dart:async';

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
/// APIs (master spec §3). Timezone handling follows master spec §14
/// — see ADR-007.
///
/// Notification-tap handling is deliberately the simple case only —
/// tap opens the app and navigates to the alarm screen, not a
/// full-screen intent. See ADR-008.
class NotificationService implements AlarmNotifier {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  final StreamController<String> _tapController =
      StreamController<String>.broadcast();

  static const String _channelId = 'guiago_alarms';
  static const String _channelName = 'GuiaGo — Lembretes';
  static const String _channelDescription =
      'Lembretes de tarefas agendados pelo GuiaGo';

  @override
  Stream<String> get onNotificationTapped => _tapController.stream;

  Future<Result<void>> initialize() async {
    if (_initialized) return const Success<void>(null);
    try {
      tz_data.initializeTimeZones();
      final TimezoneInfo deviceTimezone =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));

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
        onDidReceiveNotificationResponse: _handleTap,
      );

      // The Android notification channel (id/name/description
      // above) is created automatically the first time a
      // notification using it is shown, from the
      // AndroidNotificationDetails passed in scheduleAt() below —
      // no separate explicit creation step needed.

      _initialized = true;
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        PlatformFailure('Failed to initialize notifications', cause: e),
      );
    }
  }

  void _handleTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _tapController.add(payload);
    }
  }

  @override
  Future<String?> checkLaunchPayload() async {
    await _ensureInitialized();
    final NotificationAppLaunchDetails? details =
        await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
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
    required String payload,
  }) async {
    try {
      await _ensureInitialized();
      final tz.TZDateTime scheduled = tz.TZDateTime.from(scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        payload: payload,
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
      return Fail<void>(AlarmFailure('Failed to schedule alarm', cause: e));
    }
  }

  @override
  Future<Result<void>> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(AlarmFailure('Failed to cancel alarm', cause: e));
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

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}
