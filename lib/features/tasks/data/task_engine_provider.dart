import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scheduler/data/scheduler_providers.dart';
import '../application/task_engine.dart';
import 'task_providers.dart';

/// Composes [TaskEngine] with [SchedulerEngine] (Fase 3).
///
/// Kept in its own file, separate from `task_providers.dart`,
/// because [TaskEngine] depends on `scheduler/data`'s
/// `schedulerEngineProvider`, which itself depends on
/// `task_providers.dart`'s repository providers — composing them in
/// the same file on both sides would create a circular import.
/// Presentation code should import THIS file (not
/// `task_providers.dart`) whenever it needs `taskEngineProvider`.
final Provider<TaskEngine> taskEngineProvider = Provider<TaskEngine>((ref) {
  return TaskEngine(
    taskRepository: ref.watch(taskRepositoryProvider),
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    eventRepository: ref.watch(taskEventRepositoryProvider),
    schedulerEngine: ref.watch(schedulerEngineProvider),
  );
});
