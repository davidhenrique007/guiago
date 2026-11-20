import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/tasks_list_providers.dart';
import 'tasks_view_state.dart';

/// Thrown into the [AsyncValue] when the lists cannot be loaded, so
/// the UI can show an error state.
class TasksLoadException implements Exception {
  const TasksLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'TasksLoadException: ${failure.message}';
}

class TasksController extends AsyncNotifier<TasksSnapshot> {
  @override
  Future<TasksSnapshot> build() async {
    final Result<TasksSnapshot> result =
        await ref.read(tasksServiceProvider).load();
    return switch (result) {
      Success<TasksSnapshot>(:final value) => value,
      Fail<TasksSnapshot>(:final failure) => throw TasksLoadException(failure),
    };
  }

  /// Pull-to-refresh, or after creating/removing a task.
  void refresh() => ref.invalidateSelf();
}

final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, TasksSnapshot>(TasksController.new);
