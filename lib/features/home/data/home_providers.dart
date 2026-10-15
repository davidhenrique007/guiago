import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/settings_repository_provider.dart';
import '../../tasks/data/task_providers.dart';
import '../application/home_service.dart';

final Provider<HomeService> homeServiceProvider = Provider<HomeService>((
  ref,
) {
  return HomeService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});
