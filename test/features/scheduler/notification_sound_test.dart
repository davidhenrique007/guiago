import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/scheduler/domain/alarm_channel_spec.dart';
import 'package:guiago/features/scheduler/domain/notification_sound.dart';

void main() {
  group('NotificationSound', () {
    test('fromKey finds every sound by its stored key', () {
      for (final NotificationSound sound in NotificationSound.values) {
        expect(NotificationSound.fromKey(sound.key), sound);
      }
    });

    test('an unknown or missing key falls back to the system sound', () {
      expect(NotificationSound.fromKey('nope'), NotificationSound.system);
      expect(NotificationSound.fromKey(null), NotificationSound.system);
      expect(NotificationSound.fromKey(''), NotificationSound.system);
    });

    test('keys are unique and only "none" is silent', () {
      final Set<String> keys =
          NotificationSound.values.map((NotificationSound s) => s.key).toSet();
      expect(keys.length, NotificationSound.values.length);
      expect(
        NotificationSound.values.where((s) => !s.playsSound),
        <NotificationSound>[NotificationSound.none],
      );
    });

    test('every GuiaGo sound has its audio file in the Android resources', () {
      for (final NotificationSound sound in NotificationSound.values) {
        final String? raw = sound.rawResource;
        if (raw == null) continue;
        expect(
          File('android/app/src/main/res/raw/$raw.wav').existsSync(),
          isTrue,
          reason: 'missing res/raw/$raw.wav for ${sound.key}',
        );
      }
    });
  });

  group('AlarmChannelSpec', () {
    test('system sound with vibration keeps the original channel id', () {
      final AlarmChannelSpec spec = AlarmChannelSpec.forPreferences(
        sound: NotificationSound.system,
        vibration: true,
      );

      expect(spec.id, 'guiago_alarms');
      expect(spec.rawResource, isNull);
      expect(spec.playSound, isTrue);
    });

    test('every sound + vibration combination has its own channel', () {
      final Set<String> ids = <String>{};
      for (final NotificationSound sound in NotificationSound.values) {
        for (final bool vibration in <bool>[true, false]) {
          ids.add(
            AlarmChannelSpec.forPreferences(
              sound: sound,
              vibration: vibration,
            ).id,
          );
        }
      }

      expect(ids.length, NotificationSound.values.length * 2);
    });

    test('the spec carries the sound file, silence and vibration', () {
      final AlarmChannelSpec alert = AlarmChannelSpec.forPreferences(
        sound: NotificationSound.alert,
        vibration: false,
      );
      expect(alert.rawResource, 'guiago_alert');
      expect(alert.vibration, isFalse);

      final AlarmChannelSpec silent = AlarmChannelSpec.forPreferences(
        sound: NotificationSound.none,
        vibration: true,
      );
      expect(silent.playSound, isFalse);
      expect(silent.rawResource, isNull);
    });
  });
}
