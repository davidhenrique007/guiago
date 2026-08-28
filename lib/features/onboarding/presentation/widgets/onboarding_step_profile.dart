import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import 'onboarding_step_layout.dart';

class OnboardingStepProfile extends ConsumerStatefulWidget {
  const OnboardingStepProfile({required this.settings, super.key});

  final Settings settings;

  @override
  ConsumerState<OnboardingStepProfile> createState() =>
      _OnboardingStepProfileState();
}

class _OnboardingStepProfileState extends ConsumerState<OnboardingStepProfile> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.settings.userName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: 'Como quer ser chamado?',
      subtitle: 'Vamos usar isto para personalizar a sua experiência.',
      child: AppTextField(
        label: 'Nome',
        hint: 'O seu nome',
        autofocus: true,
        controller: _controller,
        onChanged: (String value) => ref
            .read(onboardingControllerProvider.notifier)
            .updateUserName(value),
      ),
    );
  }
}
