import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scheduler/data/scheduler_providers.dart';
import '../../tasks/data/task_providers.dart';
import '../application/recovery_service.dart';

final Provider<RecoveryService> recoveryServiceProvider =
    Provider<RecoveryService>((ref) {
  return RecoveryService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskEngine: ref.watch(taskEngineWithSchedulerProvider),
    scheduler: ref.watch(schedulerEngineProvider),
  );
});
