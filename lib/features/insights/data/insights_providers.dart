import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/task_providers.dart';
import '../application/insights_service.dart';

final Provider<InsightsService> insightsServiceProvider =
    Provider<InsightsService>((ref) {
  return InsightsService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});
