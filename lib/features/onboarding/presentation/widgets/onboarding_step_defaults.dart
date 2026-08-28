import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import 'onboarding_step_layout.dart';

class OnboardingStepDefaults extends ConsumerWidget {
  const OnboardingStepDefaults({required this.settings, super.key});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingController controller =
        ref.read(onboardingControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'Snooze e tolerância padrão',
      subtitle: 'Usados quando uma tarefa não define os seus próprios '
          'valores. Pode ajustar por tarefa mais tarde.',
      child: Column(
        children: <Widget>[
          _MinutesStepper(
            label: 'Snooze padrão',
            minutes: settings.defaultSnoozeMinutes,
            min: 1,
            max: 60,
            onChanged: (int v) => controller.updateDefaults(snoozeMinutes: v),
          ),
          const SizedBox(height: AppSpacing.md),
          _MinutesStepper(
            label: 'Tolerância padrão',
            minutes: settings.defaultToleranceMinutes,
            min: 1,
            max: 120,
            onChanged: (int v) =>
                controller.updateDefaults(toleranceMinutes: v),
          ),
        ],
      ),
    );
  }
}

class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({
    required this.label,
    required this.minutes,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

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
                Text(label, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text('$minutes min', style: AppTypography.bodyMedium),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
            onPressed: minutes > min ? () => onChanged(minutes - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
            onPressed: minutes < max ? () => onChanged(minutes + 1) : null,
          ),
        ],
      ),
    );
  }
}
