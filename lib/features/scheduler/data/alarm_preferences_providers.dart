import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../onboarding/data/settings_repository_provider.dart';
import '../../recovery/data/recovery_providers.dart';
import '../application/alarm_preferences_applier.dart';
import '../domain/alarm_notifier.dart';
import '../domain/alarm_preferences.dart';
import '../domain/alarm_sound_previewer.dart';
import '../domain/notification_sound.dart';
import 'scheduler_providers.dart';
import 'settings_alarm_preferences_source.dart';

final Provider<AlarmPreferencesSource> alarmPreferencesSourceProvider =
    Provider<AlarmPreferencesSource>(
  (ref) => SettingsAlarmPreferencesSource(
    ref.watch(settingsRepositoryProvider),
  ),
);

/// Re-applies the preferences to the alarms already scheduled.
final Provider<AlarmPreferencesApplier> alarmPreferencesApplierProvider =
    Provider<AlarmPreferencesApplier>((ref) {
  final AlarmNotifier notifier = ref.watch(notificationServiceProvider);
  return AlarmPreferencesApplier(
    notifier: notifier,
    rearm: () => ref.read(recoveryServiceProvider).run(),
  );
});

/// The real notification service can preview sounds; a fake notifier
/// (tests) cannot, and previewing then does nothing.
final Provider<AlarmSoundPreviewer> alarmSoundPreviewerProvider =
    Provider<AlarmSoundPreviewer>((ref) {
  // Typed as Object so the `is` check promotes to the previewer
  // interface (AlarmNotifier alone never would).
  final Object notifier = ref.watch(notificationServiceProvider);
  if (notifier is AlarmSoundPreviewer) return notifier;
  return const _NoPreview();
});

class _NoPreview implements AlarmSoundPreviewer {
  const _NoPreview();

  @override
  Future<Result<void>> preview(
    NotificationSound sound, {
    required bool vibration,
  }) async =>
      const Success<void>(null);
}
