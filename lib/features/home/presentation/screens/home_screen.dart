import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/refresh_task_views.dart';
import '../../../../core/result/result.dart';
import '../../../../design_system/design_system.dart';
import '../../application/home_controller.dart';
import '../../application/home_task_actions.dart';
import '../../data/home_providers.dart';
import '../../domain/home_snapshot.dart';
import '../widgets/alarm_permission_banner.dart';
import '../widgets/home_greeting.dart';
import '../widgets/home_next_task_card.dart';
import '../widgets/home_progress_card.dart';
import '../widgets/home_today_list.dart';

/// The Home (master spec §22) — the app's hub: greeting, today's
/// progress, the next pending task, and the rest of today's list.
/// Purely a view over what [HomeController] loads.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeSnapshot> snapshotAsync = ref.watch(
      homeControllerProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(homeControllerProvider.notifier).refresh();
            await ref.read(homeControllerProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const AlarmPermissionBanner(),
              // Pattern-matching, not `.when()` — same convention as
              // AlarmRingController / DashboardScreen.
              switch (snapshotAsync) {
                AsyncData<HomeSnapshot>(:final value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      HomeGreeting(
                        userName: value.userName,
                        today: value.today,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HomeProgressCard(snapshot: value),
                      const SizedBox(height: AppSpacing.md),
                      HomeNextTaskCard(
                        nextTask: value.nextTask,
                        onComplete: (String id) => _run(
                          context,
                          ref,
                          (HomeTaskActions a) => a.complete(id),
                        ),
                        onSnooze: (String id) => _run(
                          context,
                          ref,
                          (HomeTaskActions a) => a.snooze(id),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Hoje', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      HomeTodayList(
                        items: value.todayTasks,
                        onComplete: (String id) => _run(
                          context,
                          ref,
                          (HomeTaskActions a) => a.complete(id),
                        ),
                        onSnooze: (String id) => _run(
                          context,
                          ref,
                          (HomeTaskActions a) => a.snooze(id),
                        ),
                      ),
                    ],
                  ),
                AsyncError<HomeSnapshot>() => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                    ),
                    child: AppErrorState(
                      message: 'Não foi possível carregar a tua Home.',
                      onRetry: () =>
                          ref.read(homeControllerProvider.notifier).refresh(),
                    ),
                  ),
                _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppLoadingState(),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  /// Runs a quick action, tells the user when it fails, and reloads
  /// every tab that shows tasks.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Result<void>> Function(HomeTaskActions actions) action,
  ) async {
    final Result<void> result = await action(ref.read(homeTaskActionsProvider));
    if (!context.mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.failureOrNull?.message ?? 'Não foi possível atualizar.',
          ),
        ),
      );
    }
    refreshTaskViews(ref);
  }
}
