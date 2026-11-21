import 'notification_sound.dart';

/// The Android notification channel that matches a sound + vibration
/// choice.
///
/// On Android 8+ the sound and vibration belong to the *channel* and
/// cannot be changed once the channel exists, so every combination has
/// its own channel id. The combination used before sounds were
/// configurable (system sound, with vibration) keeps the original id,
/// so existing installs keep their channel.
class AlarmChannelSpec {
  const AlarmChannelSpec({
    required this.id,
    required this.name,
    required this.sound,
    required this.vibration,
  });

  factory AlarmChannelSpec.forPreferences({
    required NotificationSound sound,
    required bool vibration,
  }) {
    final bool legacy = sound == NotificationSound.system && vibration;
    final String id = legacy
        ? legacyId
        : 'guiago_alarms_${sound.key}_${vibration ? 'v' : 'q'}';
    final String vibrationLabel = vibration ? 'com vibração' : 'sem vibração';
    return AlarmChannelSpec(
      id: id,
      name: 'GuiaGo — ${sound.label} ($vibrationLabel)',
      sound: sound,
      vibration: vibration,
    );
  }

  static const String legacyId = 'guiago_alarms';

  final String id;
  final String name;
  final NotificationSound sound;
  final bool vibration;

  bool get playSound => sound.playsSound;
  String? get rawResource => sound.rawResource;
}
