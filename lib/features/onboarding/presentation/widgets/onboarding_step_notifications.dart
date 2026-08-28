import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import 'onboarding_step_layout.dart';

class OnboardingStepNotifications extends ConsumerWidget {
  const OnboardingStepNotifications({required this.settings, super.key});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingController controller =
        ref.read(onboardingControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'Como quer ser avisado?',
      subtitle: 'Pode alterar isto mais tarde nas definições.',
      child: Column(
        children: <Widget>[
          _PreferenceSwitch(
            title: 'Notificações',
            subtitle: 'Alarmes e lembretes de tarefas',
            value: settings.notificationsEnabled,
            onChanged: controller.updateNotificationsEnabled,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PreferenceSwitch(
            title: 'Leitura por voz (TTS)',
            subtitle: 'O GuiaGo lê a tarefa em voz alta ao disparar',
            value: settings.ttsEnabled,
            onChanged: controller.updateTtsEnabled,
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
