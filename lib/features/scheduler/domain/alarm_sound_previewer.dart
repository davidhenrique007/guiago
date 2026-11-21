import '../../../core/result/result.dart';
import 'notification_sound.dart';

/// Lets the user hear a sound before choosing it. Implemented by the
/// notification service (it fires a test notification on the real
/// channel, so what is heard is exactly what the alarm will use).
abstract interface class AlarmSoundPreviewer {
  Future<Result<void>> preview(
    NotificationSound sound, {
    required bool vibration,
  });
}
