import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';

/// First screen a new user sees. Its only job is to set the tone
/// (calm, disciplined, premium — §7) and lead into onboarding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Bem-vindo ao GuiaGo',
                textAlign: TextAlign.center,
                style: AppTypography.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Não é só lembrar o que precisa fazer.\n'
                'É ajudar a realmente fazer.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              AppButton(
                label: 'Começar',
                onPressed: () => context.go(AppRoutes.onboarding),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
