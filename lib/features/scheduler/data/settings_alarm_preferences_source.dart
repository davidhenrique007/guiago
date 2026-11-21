import '../../onboarding/domain/settings.dart';
import '../../onboarding/domain/settings_repository.dart';
import '../domain/alarm_preferences.dart';
import '../domain/notification_sound.dart';

/// Reads the alarm preferences from the saved settings.
class SettingsAlarmPreferencesSource implements AlarmPreferencesSource {
  const SettingsAlarmPreferencesSource(this._settings);

  final SettingsRepository _settings;

  @override
  Future<AlarmPreferences> current() async {
    final Settings? settings = (await _settings.getSettings()).valueOrNull;
    if (settings == null) return AlarmPreferences.fallback;
    return AlarmPreferences(
      notificationsEnabled: settings.notificationsEnabled,
      sound: NotificationSound.fromKey(settings.notificationSound),
      vibrationEnabled: settings.vibrationEnabled,
    );
  }
}
