import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/settings.dart';

/// Boots the app: loads [Settings] and routes to Onboarding (first
/// run) or Home (returning user) — master spec §22/§26.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final Settings settings =
        await ref.read(onboardingControllerProvider.future);
    if (!mounted) return;

    if (settings.onboardingCompleted) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppDurations.slow,
          curve: AppCurves.standard,
          builder: (BuildContext context, double opacity, Widget? child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('GuiaGo', style: AppTypography.displayLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Organize. Aja. Avance.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
