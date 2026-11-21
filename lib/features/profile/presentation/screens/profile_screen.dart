import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/result/result.dart';
import '../../../../design_system/design_system.dart';
import '../../../home/application/home_controller.dart';
import '../../../onboarding/application/settings_controller.dart';
import '../../../onboarding/domain/settings.dart';
import '../../../scheduler/data/alarm_preferences_providers.dart';
import '../../../scheduler/domain/notification_sound.dart';
import '../../../tasks/presentation/widgets/task_create_options.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_minutes_picker.dart';
import '../widgets/profile_preferences_card.dart';
import '../widgets/profile_sound_picker.dart';

/// The Perfil tab: who the user is (editable), the link to Insights
/// and the preferences (editable). Changes go through
/// [SettingsController.saveChange].
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Saves a change and tells the user if it failed. The Home shows the
  /// user's name, so it is reloaded after a successful save. With
  /// [affectsAlarms] the alarms already scheduled are re-armed (or
  /// cancelled, when notifications are off) so the change applies to them.
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Settings Function(Settings current) change, {
    bool affectsAlarms = false,
  }) async {
    final Result<void> result =
        await ref.read(settingsControllerProvider.notifier).saveChange(change);
    if (!context.mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível guardar.')),
      );
      return;
    }
    ref.invalidate(homeControllerProvider);
    if (affectsAlarms) {
      final bool enabled = switch (ref.read(settingsControllerProvider)) {
        AsyncData<Settings>(:final value) => value.notificationsEnabled,
        _ => true,
      };
      unawaited(
        ref
            .read(alarmPreferencesApplierProvider)
            .apply(notificationsEnabled: enabled),
      );
    }
  }

  Future<void> _pickSound(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) async {
    final NotificationSound? sound = await ProfileSoundPicker.show(
      context,
      selected: NotificationSound.fromKey(settings.notificationSound),
      onPreview: (NotificationSound s) async {
        // Hear it with the vibration setting the alarm will use.
        await ref.read(alarmSoundPreviewerProvider).preview(
              s,
              vibration: settings.vibrationEnabled,
            );
      },
    );
    if (sound == null || !context.mounted) return;
    await _save(
      context,
      ref,
      (Settings s) => s.copyWith(notificationSound: sound.key),
      affectsAlarms: true,
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) async {
    final ProfileEdit? edit = await ProfileEditSheet.show(
      context,
      name: settings.userName,
      objective: settings.mainObjective,
    );
    if (edit == null || !context.mounted) return;
    await _save(
      context,
      ref,
      (Settings s) =>
          s.copyWith(userName: edit.name, mainObjective: edit.objective),
    );
  }

  Future<void> _pickMinutes(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<int> options,
    required int selected,
    required Settings Function(Settings s, int minutes) apply,
  }) async {
    final int? minutes = await ProfileMinutesPicker.show(
      context,
      title: title,
      options: options,
      selected: selected,
    );
    if (minutes == null || !context.mounted) return;
    await _save(context, ref, (Settings s) => apply(s, minutes));
  }

  Future<void> _pickDayTime(
    BuildContext context,
    WidgetRef ref,
    Settings settings, {
    required bool isStart,
  }) async {
    final int current =
        isStart ? settings.dayStartMinutes : settings.dayEndMinutes;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null || !context.mounted) return;

    final int minutes = picked.hour * 60 + picked.minute;
    final int start = isStart ? minutes : settings.dayStartMinutes;
    final int end = isStart ? settings.dayEndMinutes : minutes;
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O fim do dia tem de ser depois do início.'),
        ),
      );
      return;
    }
    await _save(
      context,
      ref,
      (Settings s) => isStart
          ? s.copyWith(dayStartMinutes: minutes)
          : s.copyWith(dayEndMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Settings> settingsAsync = ref.watch(
      settingsControllerProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Perfil', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(settingsControllerProvider.notifier).refresh();
            await ref.read(settingsControllerProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              // Pattern-matching, not `.when()` (see HomeScreen).
              switch (settingsAsync) {
                AsyncData<Settings>(:final value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ProfileHeader(
                        settings: value,
                        onEdit: () => _editProfile(context, ref, value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        onTap: () =>
                            context.pushNamed(AppRoutes.profileInsightsName),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.insights_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Insights',
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'O teu melhor horário e as tarefas '
                                    'que mais concluis.',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ProfilePreferencesCard(
                        settings: value,
                        onNotificationsChanged: (bool enabled) => _save(
                          context,
                          ref,
                          (Settings s) =>
                              s.copyWith(notificationsEnabled: enabled),
                          affectsAlarms: true,
                        ),
                        onSoundTap: () => _pickSound(context, ref, value),
                        onVibrationChanged: (bool enabled) => _save(
                          context,
                          ref,
                          (Settings s) => s.copyWith(vibrationEnabled: enabled),
                          affectsAlarms: true,
                        ),
                        onTtsChanged: (bool enabled) => _save(
                          context,
                          ref,
                          (Settings s) => s.copyWith(ttsEnabled: enabled),
                        ),
                        onSnoozeTap: () => _pickMinutes(
                          context,
                          ref,
                          title: 'Snooze padrão',
                          options: TaskCreateOptions.snoozeMinutes,
                          selected: value.defaultSnoozeMinutes,
                          apply: (Settings s, int minutes) =>
                              s.copyWith(defaultSnoozeMinutes: minutes),
                        ),
                        onToleranceTap: () => _pickMinutes(
                          context,
                          ref,
                          title: 'Tolerância padrão',
                          options: TaskCreateOptions.toleranceMinutes,
                          selected: value.defaultToleranceMinutes,
                          apply: (Settings s, int minutes) =>
                              s.copyWith(defaultToleranceMinutes: minutes),
                        ),
                        onDayStartTap: () =>
                            _pickDayTime(context, ref, value, isStart: true),
                        onDayEndTap: () =>
                            _pickDayTime(context, ref, value, isStart: false),
                      ),
                    ],
                  ),
                AsyncError<Settings>() => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar o perfil.',
                      onRetry: () => ref
                          .read(settingsControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppLoadingState(),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
