import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';
import '../widgets/onboarding_step_day_window.dart';
import '../widgets/onboarding_step_defaults.dart';
import '../widgets/onboarding_step_notifications.dart';
import '../widgets/onboarding_step_objective.dart';
import '../widgets/onboarding_step_profile.dart';

/// The 5-step onboarding flow (master spec §1 Fase 1 / §23): Perfil,
/// Objetivo, Horário do dia, Notificações/TTS, Snooze/Tolerância.
///
/// Owns only UI-local state (which page is showing). The actual
/// answers live in [OnboardingController] so a step never loses data
/// if the user goes back and forth.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _stepCount = 5;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _stepCount - 1;

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: AppDurations.medium,
      curve: AppCurves.standard,
    );
  }

  Future<void> _onNext() async {
    if (!_isLastStep) {
      _goToStep(_currentStep + 1);
      return;
    }
    await _complete();
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    final Result<void> result =
        await ref.read(onboardingControllerProvider.notifier).complete();
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) => context.go(AppRoutes.home),
      failure: (Failure failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível guardar as suas preferências. '
              'Tente novamente.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Settings> onboardingState =
        ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: onboardingState.when(
          loading: () => const AppLoadingState(),
          error: (Object error, StackTrace stackTrace) => AppErrorState(
            message: 'Não foi possível carregar as suas preferências.',
            onRetry: () => ref.invalidate(onboardingControllerProvider),
          ),
          data: (Settings settings) => _OnboardingFlowBody(
            settings: settings,
            pageController: _pageController,
            currentStep: _currentStep,
            stepCount: _stepCount,
            isSaving: _isSaving,
            isLastStep: _isLastStep,
            onPageChanged: (int page) => setState(() => _currentStep = page),
            onBack:
                _currentStep == 0 ? null : () => _goToStep(_currentStep - 1),
            onNext: _onNext,
          ),
        ),
      ),
    );
  }
}

class _OnboardingFlowBody extends StatelessWidget {
  const _OnboardingFlowBody({
    required this.settings,
    required this.pageController,
    required this.currentStep,
    required this.stepCount,
    required this.isSaving,
    required this.isLastStep,
    required this.onPageChanged,
    required this.onBack,
    required this.onNext,
  });

  final Settings settings;
  final PageController pageController;
  final int currentStep;
  final int stepCount;
  final bool isSaving;
  final bool isLastStep;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppProgress(value: (currentStep + 1) / stepCount),
        ),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: onPageChanged,
            children: <Widget>[
              OnboardingStepProfile(settings: settings),
              OnboardingStepObjective(settings: settings),
              OnboardingStepDayWindow(settings: settings),
              OnboardingStepNotifications(settings: settings),
              OnboardingStepDefaults(settings: settings),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              if (onBack != null) ...<Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Voltar',
                    variant: AppButtonVariant.secondary,
                    onPressed: isSaving ? null : onBack,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: onBack != null ? 1 : 2,
                child: AppButton(
                  label: isLastStep ? 'Concluir' : 'Continuar',
                  isLoading: isSaving,
                  onPressed: isSaving ? null : onNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
