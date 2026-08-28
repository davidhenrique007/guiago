import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';

/// User profile + preferences captured during onboarding (master spec
/// §Fase 1: Perfil, Objetivo principal, horário de início/fim do dia,
/// preferências de notificação, TTS, snooze e tolerância padrão).
///
/// Pure Dart, Freezed value model — no Flutter, no Drift import here.
@freezed
sealed class Settings with _$Settings {
  const factory Settings({
    required String userName,
    required String mainObjective,
    required int dayStartMinutes,
    required int dayEndMinutes,
    required bool notificationsEnabled,
    required bool ttsEnabled,
    required int defaultSnoozeMinutes,
    required int defaultToleranceMinutes,
    required bool onboardingCompleted,
  }) = _Settings;

  const Settings._();

  /// Defaults shown the first time onboarding runs.
  static const Settings initial = Settings(
    userName: '',
    mainObjective: '',
    dayStartMinutes: 7 * 60,
    dayEndMinutes: 22 * 60,
    notificationsEnabled: true,
    ttsEnabled: true,
    defaultSnoozeMinutes: 10,
    defaultToleranceMinutes: 15,
    onboardingCompleted: false,
  );

  String get dayStartLabel => _formatMinutes(dayStartMinutes);
  String get dayEndLabel => _formatMinutes(dayEndMinutes);

  static String _formatMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
