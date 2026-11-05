import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../application/home_controller.dart';
import '../../domain/home_snapshot.dart';
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Nova tarefa',
        onPressed: () async {
          await context.pushNamed(AppRoutes.taskCreateName);
          // A tarefa criada pode ter ficado para hoje — recarrega.
          ref.read(homeControllerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
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
                      HomeNextTaskCard(nextTask: value.nextTask),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Hoje', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      HomeTodayList(items: value.todayTasks),
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
}
