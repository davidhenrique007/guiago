import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../onboarding/domain/settings.dart';

/// Read-only list of the preferences captured in onboarding.
class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({required this.settings, super.key});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Início do dia', settings.dayStartLabel),
      ('Fim do dia', settings.dayEndLabel),
      (
        'Notificações',
        settings.notificationsEnabled ? 'Ativadas' : 'Desativadas',
      ),
      ('Voz (TTS)', settings.ttsEnabled ? 'Ativada' : 'Desativada'),
      ('Snooze padrão', '${settings.defaultSnoozeMinutes} min'),
      ('Tolerância padrão', '${settings.defaultToleranceMinutes} min'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('PREFERÊNCIAS', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.md - 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(rows[i].$1, style: AppTypography.bodyMedium),
                ),
                Text(
                  rows[i].$2,
                  style: AppTypography.mono.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
