// GuiaGo — Fase 5: Performance Engine + Gamification
// Providers Riverpod — mesmo padrão de task_providers.dart e
// scheduler_providers.dart: Provider<T> simples, repositórios
// observam appDatabaseProvider, engines são stateless (const).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../tasks/data/task_providers.dart';
import '../application/level_engine.dart';
import '../application/performance_controller.dart';
import '../application/performance_engine.dart';
import '../application/score_engine.dart';
import '../application/streak_engine.dart';
import '../domain/level_repository.dart';
import '../domain/performance_record_repository.dart';
import '../domain/score_repository.dart';
import '../domain/streak_repository.dart';
import 'drift_level_repository.dart';
import 'drift_performance_record_repository.dart';
import 'drift_score_repository.dart';
import 'drift_streak_repository.dart';
import 'occurrence_outcome_mapper.dart';

// --- Repositórios ---

final Provider<PerformanceRecordRepository>
    performanceRecordRepositoryProvider =
    Provider<PerformanceRecordRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftPerformanceRecordRepository(db);
});

final Provider<ScoreRepository> scoreRepositoryProvider =
    Provider<ScoreRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftScoreRepository(db);
});

final Provider<LevelRepository> levelRepositoryProvider =
    Provider<LevelRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftLevelRepository(db);
});

final Provider<StreakRepository> streakRepositoryProvider =
    Provider<StreakRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftStreakRepository(db);
});

// --- Mapper ---

final Provider<OccurrenceOutcomeMapper> occurrenceOutcomeMapperProvider =
    Provider<OccurrenceOutcomeMapper>(
  (ref) => const OccurrenceOutcomeMapper(),
);

// --- Engines (stateless, sem dependências — const direto) ---

final Provider<PerformanceEngine> performanceEngineProvider =
    Provider<PerformanceEngine>((ref) => const PerformanceEngine());

final Provider<ScoreEngine> scoreEngineProvider = Provider<ScoreEngine>(
  (ref) => const ScoreEngine(),
);

final Provider<LevelEngine> levelEngineProvider = Provider<LevelEngine>(
  (ref) => const LevelEngine(),
);

final Provider<StreakEngine> streakEngineProvider = Provider<StreakEngine>(
  (ref) => const StreakEngine(),
);

// --- Controller (orquestra tudo acima) ---

final Provider<PerformanceController> performanceControllerProvider =
    Provider<PerformanceController>((ref) {
  return PerformanceController(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    mapper: ref.watch(occurrenceOutcomeMapperProvider),
    performanceEngine: ref.watch(performanceEngineProvider),
    scoreEngine: ref.watch(scoreEngineProvider),
    levelEngine: ref.watch(levelEngineProvider),
    streakEngine: ref.watch(streakEngineProvider),
    performanceRecordRepository: ref.watch(performanceRecordRepositoryProvider),
    scoreRepository: ref.watch(scoreRepositoryProvider),
    levelRepository: ref.watch(levelRepositoryProvider),
    streakRepository: ref.watch(streakRepositoryProvider),
  );
});
