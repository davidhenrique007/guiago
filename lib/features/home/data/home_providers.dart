import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/settings_repository_provider.dart';
import '../../scheduler/data/scheduler_providers.dart';
import '../../tasks/data/task_providers.dart';
import '../application/home_service.dart';
import '../application/home_task_actions.dart';

final Provider<HomeService> homeServiceProvider = Provider<HomeService>((
  ref,
) {
  return HomeService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final Provider<HomeTaskActions> homeTaskActionsProvider =
    Provider<HomeTaskActions>((ref) {
  return HomeTaskActions(
    taskEngine: ref.watch(taskEngineWithSchedulerProvider),
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});
