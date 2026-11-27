import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_mode.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_language.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/domain/settings.dart';
import '../../../scheduler/domain/notification_sound.dart';
import 'profile_sound_picker.dart';
import 'profile_theme_picker.dart';

/// The user's preferences. Every row is editable: switches change on
/// tap, the others open a picker. A row whose callback is null is
/// shown read-only.
class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({
    required this.settings,
    this.onNotificationsChanged,
    this.onSoundTap,
    this.onVibrationChanged,
    this.onTtsChanged,
    this.onSnoozeTap,
    this.onToleranceTap,
    this.onThemeTap,
    this.onLanguageTap,
    this.onDayStartTap,
    this.onDayEndTap,
    super.key,
  });

  final Settings settings;
  final ValueChanged<bool>? onNotificationsChanged;
  final VoidCallback? onSoundTap;
  final ValueChanged<bool>? onVibrationChanged;
  final ValueChanged<bool>? onTtsChanged;
  final VoidCallback? onSnoozeTap;
  final VoidCallback? onToleranceTap;
  final VoidCallback? onThemeTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onDayStartTap;
  final VoidCallback? onDayEndTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.sectionNotifications, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: l10n.rowNotifications,
            value: settings.notificationsEnabled
                ? l10n.stateEnabled
                : l10n.stateDisabled,
            switchValue: settings.notificationsEnabled,
            onSwitch: onNotificationsChanged,
          ),
          _ValueRow(
            label: l10n.rowSound,
            value: ProfileSoundPicker.soundLabel(
              l10n,
              NotificationSound.fromKey(settings.notificationSound),
            ),
            onTap: onSoundTap,
          ),
          _ValueRow(
            label: l10n.rowVibration,
            value: settings.vibrationEnabled
                ? l10n.vibrationOn
                : l10n.vibrationOff,
            switchValue: settings.vibrationEnabled,
            onSwitch: onVibrationChanged,
          ),
          _ValueRow(
            label: l10n.rowSnooze,
            value: l10n.minutes(settings.defaultSnoozeMinutes),
            onTap: onSnoozeTap,
          ),
          _ValueRow(
            label: l10n.rowTolerance,
            value: l10n.minutes(settings.defaultToleranceMinutes),
            onTap: onToleranceTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.sectionAppearance, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: l10n.rowTheme,
            value: ProfileThemePicker.themeModeLabel(
              l10n,
              AppThemeMode.fromKey(settings.themeMode),
            ),
            onTap: onThemeTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.sectionLanguage, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: l10n.rowLanguage,
            value: AppLanguage.fromCode(settings.languageCode).label,
            onTap: onLanguageTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.sectionOther, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: l10n.rowTts,
            value: settings.ttsEnabled ? l10n.ttsOn : l10n.ttsOff,
            switchValue: settings.ttsEnabled,
            onSwitch: onTtsChanged,
          ),
          _ValueRow(
            label: l10n.rowDayStart,
            value: settings.dayStartLabel,
            onTap: onDayStartTap,
          ),
          _ValueRow(
            label: l10n.rowDayEnd,
            value: settings.dayEndLabel,
            onTap: onDayEndTap,
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.onTap,
    this.switchValue,
    this.onSwitch,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// When non-null the row ends with a [Switch].
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;

  @override
  Widget build(BuildContext context) {
    final bool hasSwitch = switchValue != null && onSwitch != null;
    return InkWell(
      onTap: hasSwitch ? () => onSwitch!(!switchValue!) : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            Text(
              value,
              style: AppTypography.mono.copyWith(color: AppColors.textPrimary),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue!,
                onChanged: onSwitch,
                activeTrackColor: AppColors.primary,
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
