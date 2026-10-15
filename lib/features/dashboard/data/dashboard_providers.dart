import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../performance/data/performance_providers.dart';
import '../../tasks/data/task_providers.dart';
import '../application/dashboard_service.dart';
import '../application/trend_engine.dart';

final Provider<TrendEngine> trendEngineProvider =
    Provider<TrendEngine>((ref) => const TrendEngine());

final Provider<DashboardService> dashboardServiceProvider =
    Provider<DashboardService>((ref) {
  return DashboardService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    mapper: ref.watch(occurrenceOutcomeMapperProvider),
    performanceEngine: ref.watch(performanceEngineProvider),
    trendEngine: ref.watch(trendEngineProvider),
    scoreRepository: ref.watch(scoreRepositoryProvider),
    levelRepository: ref.watch(levelRepositoryProvider),
    streakRepository: ref.watch(streakRepositoryProvider),
  );
});
