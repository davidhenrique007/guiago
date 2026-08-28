import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../domain/task_event_repository.dart';
import '../domain/task_occurrence_repository.dart';
import '../domain/task_repository.dart';
import 'drift_task_event_repository.dart';
import 'drift_task_occurrence_repository.dart';
import 'drift_task_repository.dart';

/// Application/Presentation code depends on the domain repository
/// interfaces; these providers are the only place that knows the
/// concrete implementations are Drift-backed.
///
/// NOTE: `taskEngineProvider` deliberately does NOT live here — see
/// `task_engine_provider.dart`. [TaskEngine] depends on
/// `SchedulerEngine` (Fase 3), and `SchedulerEngine` depends on the
/// repository providers declared in this very file, so composing
/// `TaskEngine` here would make this file and
/// `scheduler/data/scheduler_providers.dart` import each other —
/// a circular import. Splitting the composition into its own file
/// (which is free to depend on both) avoids that cycle entirely.
final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftTaskRepository(db);
});

final Provider<TaskOccurrenceRepository> taskOccurrenceRepositoryProvider =
    Provider<TaskOccurrenceRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftTaskOccurrenceRepository(db);
});

final Provider<TaskEventRepository> taskEventRepositoryProvider =
    Provider<TaskEventRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftTaskEventRepository(db);
});
