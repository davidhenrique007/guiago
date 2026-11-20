import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tasks_service.dart';
import 'task_providers.dart';

final Provider<TasksService> tasksServiceProvider = Provider<TasksService>((
  ref,
) {
  return TasksService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});
