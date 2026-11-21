import 'notification_sound.dart';

/// What the user chose about how alarms reach them.
class AlarmPreferences {
  const AlarmPreferences({
    required this.notificationsEnabled,
    required this.sound,
    required this.vibrationEnabled,
  });

  /// Used when the settings cannot be read: behave as before the
  /// preferences existed.
  static const AlarmPreferences fallback = AlarmPreferences(
    notificationsEnabled: true,
    sound: NotificationSound.system,
    vibrationEnabled: true,
  );

  final bool notificationsEnabled;
  final NotificationSound sound;
  final bool vibrationEnabled;
}

/// Where the notification service reads the preferences from, at the
/// moment it schedules. Keeps the infrastructure layer free of the
/// settings feature.
abstract interface class AlarmPreferencesSource {
  Future<AlarmPreferences> current();
}
