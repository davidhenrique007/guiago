import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/refresh_task_views.dart';
import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../scheduler/data/scheduler_providers.dart';
import '../../application/tasks_controller.dart';
import '../../application/tasks_view_state.dart';
import '../widgets/task_item_actions_sheet.dart';
import '../widgets/tasks_empty_state.dart';
import '../widgets/tasks_list_section.dart';
import '../widgets/tasks_segment_bar.dart';

/// The Tasks tab: the single place where tasks are created. Shows the
/// user's tasks as Hoje / Próximas / Concluídas. Purely a view over
/// [TasksController].
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TasksSegment _segment = TasksSegment.today;

  Future<void> _createTask() async {
    await context.pushNamed(AppRoutes.taskCreateName);
    if (!mounted) return;
    // The tabs are kept alive by the shell, so every tab that shows
    // tasks must reload after a task is created.
    refreshTaskViews(ref);
  }

  Future<void> _onItemTap(TaskListItem item) async {
    final TaskItemAction? action = await TaskItemActionsSheet.show(
      context,
      title: item.title,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case TaskItemAction.edit:
        await context.pushNamed(
          AppRoutes.taskEditName,
          pathParameters: <String, String>{'taskId': item.taskId},
        );
        if (!mounted) return;
        refreshTaskViews(ref);
      case TaskItemAction.remove:
        await _confirmAndRemove(item);
    }
  }

  Future<void> _confirmAndRemove(TaskListItem item) async {
    final bool? confirmed = await AppDialog.show(
      context,
      title: 'Apagar tarefa?',
      message: 'A tarefa "${item.title}" e os seus alarmes pendentes '
          'deixam de aparecer. O teu histórico e pontuação mantêm-se.',
      confirmLabel: 'Apagar',
    );
    if (confirmed != true || !mounted) return;

    final result =
        await ref.read(taskEngineWithSchedulerProvider).removeTask(item.taskId);
    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.failureOrNull?.message ?? 'Não foi possível apagar.',
          ),
        ),
      );
    }
    refreshTaskViews(ref);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TasksSnapshot> snapshotAsync = ref.watch(
      tasksControllerProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Tarefas', style: AppTypography.titleLarge),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Nova tarefa',
        onPressed: _createTask,
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(tasksControllerProvider.notifier).refresh();
            await ref.read(tasksControllerProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              TasksSegmentBar(
                selected: _segment,
                onSelected: (TasksSegment value) =>
                    setState(() => _segment = value),
              ),
              const SizedBox(height: AppSpacing.md),
              // Pattern-matching, not `.when()` — same convention as
              // HomeScreen / CalendarScreen.
              switch (snapshotAsync) {
                AsyncData<TasksSnapshot>(:final value) => _content(value),
                AsyncError<TasksSnapshot>() => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: AppErrorState(
                      message: 'Não foi possível carregar as tarefas.',
                      onRetry: () =>
                          ref.read(tasksControllerProvider.notifier).refresh(),
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

  Widget _content(TasksSnapshot snapshot) {
    final List<TaskListItem> items = switch (_segment) {
      TasksSegment.today => snapshot.today,
      TasksSegment.upcoming => snapshot.upcoming,
      TasksSegment.completed => snapshot.completed,
    };
    if (items.isEmpty) {
      return TasksEmptyState(
        segment: _segment,
        hasAnyTask: !snapshot.isEmpty,
        onCreate: _createTask,
      );
    }
    return TasksListSection(
      // History is read-only: only pending tasks can be edited/removed.
      onTap: _segment == TasksSegment.completed ? null : _onItemTap,
      items: items,
    );
  }
}
