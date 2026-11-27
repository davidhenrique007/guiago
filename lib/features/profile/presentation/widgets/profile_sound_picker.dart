import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../scheduler/domain/notification_sound.dart';

/// Bottom sheet to choose the alarm sound. Every sound (except
/// "Sem som") has a play button to hear it first; tapping the row
/// chooses it and closes the sheet. Returns the chosen sound, or null
/// when dismissed.
abstract final class ProfileSoundPicker {
  /// The name of [sound] in the language of [l10n].
  static String soundLabel(AppLocalizations l10n, NotificationSound sound) =>
      switch (sound) {
        NotificationSound.soft => l10n.soundSoft,
        NotificationSound.alert => l10n.soundAlert,
        NotificationSound.wake => l10n.soundWake,
        NotificationSound.system => l10n.soundSystem,
        NotificationSound.none => l10n.soundNone,
      };

  static Future<NotificationSound?> show(
    BuildContext context, {
    required NotificationSound selected,
    required Future<void> Function(NotificationSound sound) onPreview,
  }) {
    return AppBottomSheet.show<NotificationSound>(
      context,
      title: context.l10n.rowSound,
      child: Builder(
        builder: (BuildContext sheetContext) => Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final NotificationSound sound in NotificationSound.values)
                _SoundRow(
                  sound: sound,
                  isSelected: sound == selected,
                  onChoose: () => Navigator.of(sheetContext).pop(sound),
                  onPreview: () => onPreview(sound),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.sound,
    required this.isSelected,
    required this.onChoose,
    required this.onPreview,
  });

  final NotificationSound sound;
  final bool isSelected;
  final VoidCallback onChoose;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String name = ProfileSoundPicker.soundLabel(l10n, sound);
    return InkWell(
      onTap: onChoose,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(name, style: AppTypography.bodyLarge)),
            if (sound.playsSound)
              IconButton(
                tooltip: l10n.soundPreview(name),
                onPressed: onPreview,
                icon: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
