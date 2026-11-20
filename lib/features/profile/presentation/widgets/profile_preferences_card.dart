import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../onboarding/domain/settings.dart';

/// The user's preferences. Every row is editable: switches change on
/// tap, the others open a picker. A row whose callback is null is
/// shown read-only.
class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({
    required this.settings,
    this.onNotificationsChanged,
    this.onTtsChanged,
    this.onSnoozeTap,
    this.onToleranceTap,
    this.onDayStartTap,
    this.onDayEndTap,
    super.key,
  });

  final Settings settings;
  final ValueChanged<bool>? onNotificationsChanged;
  final ValueChanged<bool>? onTtsChanged;
  final VoidCallback? onSnoozeTap;
  final VoidCallback? onToleranceTap;
  final VoidCallback? onDayStartTap;
  final VoidCallback? onDayEndTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('PREFERÊNCIAS', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: 'Notificações',
            value: settings.notificationsEnabled ? 'Ativadas' : 'Desativadas',
            switchValue: settings.notificationsEnabled,
            onSwitch: onNotificationsChanged,
          ),
          _ValueRow(
            label: 'Snooze padrão',
            value: '${settings.defaultSnoozeMinutes} min',
            onTap: onSnoozeTap,
          ),
          _ValueRow(
            label: 'Tolerância padrão',
            value: '${settings.defaultToleranceMinutes} min',
            onTap: onToleranceTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('OUTRAS CONFIGURAÇÕES', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _ValueRow(
            label: 'Voz (TTS)',
            value: settings.ttsEnabled ? 'Ativada' : 'Desativada',
            switchValue: settings.ttsEnabled,
            onSwitch: onTtsChanged,
          ),
          _ValueRow(
            label: 'Início do dia',
            value: settings.dayStartLabel,
            onTap: onDayStartTap,
          ),
          _ValueRow(
            label: 'Fim do dia',
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
