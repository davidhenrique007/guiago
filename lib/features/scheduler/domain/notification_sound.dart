/// The sounds a GuiaGo alarm can use. [key] is what is stored in the
/// settings; [rawResource] is the file in `android/app/src/main/res/raw`
/// (null for the system default and for silence).
///
/// To add a sound later: drop the file in `res/raw`, add an entry here.
enum NotificationSound {
  soft('soft', 'GuiaGo — Suave', rawResource: 'guiago_soft'),
  alert('alert', 'GuiaGo — Alerta', rawResource: 'guiago_alert'),
  wake('wake', 'GuiaGo — Despertar', rawResource: 'guiago_wake'),
  system('system', 'Som do sistema'),
  none('none', 'Sem som');

  const NotificationSound(this.key, this.label, {this.rawResource});

  final String key;
  final String label;
  final String? rawResource;

  bool get playsSound => this != NotificationSound.none;

  /// An unknown or missing key falls back to the system sound, which is
  /// what every install used before sounds became configurable.
  static NotificationSound fromKey(String? key) {
    for (final NotificationSound sound in NotificationSound.values) {
      if (sound.key == key) return sound;
    }
    return NotificationSound.system;
  }
}
