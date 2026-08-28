import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import 'onboarding_step_layout.dart';

class OnboardingStepObjective extends ConsumerStatefulWidget {
  const OnboardingStepObjective({required this.settings, super.key});

  final Settings settings;

  @override
  ConsumerState<OnboardingStepObjective> createState() =>
      _OnboardingStepObjectiveState();
}

class _OnboardingStepObjectiveState
    extends ConsumerState<OnboardingStepObjective> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.settings.mainObjective);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: 'Qual é o seu objetivo principal?',
      subtitle: 'Ex: estudar todos os dias, treinar 4x por semana, '
          'organizar o trabalho.',
      child: AppTextField(
        label: 'Objetivo',
        hint: 'O que quer alcançar com o GuiaGo',
        controller: _controller,
        onChanged: (String value) => ref
            .read(onboardingControllerProvider.notifier)
            .updateMainObjective(value),
      ),
    );
  }
}
