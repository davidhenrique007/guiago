import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import 'onboarding_step_layout.dart';

class OnboardingStepDayWindow extends ConsumerWidget {
  const OnboardingStepDayWindow({required this.settings, super.key});

  final Settings settings;

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final int initialMinutes =
        isStart ? settings.dayStartMinutes : settings.dayEndMinutes;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
    );
    if (picked == null) return;

    final int minutes = picked.hour * 60 + picked.minute;
    final OnboardingController controller =
        ref.read(onboardingControllerProvider.notifier);
    if (isStart) {
      controller.updateDayWindow(dayStartMinutes: minutes);
    } else {
      controller.updateDayWindow(dayEndMinutes: minutes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingStepLayout(
      title: 'Qual é a sua janela do dia?',
      subtitle: 'O GuiaGo só agenda alarmes dentro deste horário.',
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TimeTile(
              label: 'Início',
              value: settings.dayStartLabel,
              onTap: () => _pickTime(context, ref, isStart: true),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _TimeTile(
              label: 'Fim',
              value: settings.dayEndLabel,
              onTap: () => _pickTime(context, ref, isStart: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.titleLarge),
        ],
      ),
    );
  }
}
