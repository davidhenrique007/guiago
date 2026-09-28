// GuiaGo — Fase 5: Performance Engine + Gamification
// PerformanceController
//
// Orquestra o mapper + os 4 engines + os 4 repositories desta
// fase (e o TaskOccurrenceRepository da Fase 2, via
// getOccurrencesInRange). É o único ponto que o resto da app
// precisa de chamar — nem a UI nem outra feature falam
// diretamente com os engines ou repositories individuais.
//
// Mesmo padrão de TaskEngine (Fase 2): classe simples,
// dependências injetadas via construtor, uuid opcional com
// default `const Uuid()`.

import 'package:uuid/uuid.dart';

import '../../../core/result/result.dart';
import '../../tasks/domain/occurrence_outcome_recorder.dart';
import '../../tasks/domain/task_occurrence.dart';
import '../../tasks/domain/task_occurrence_repository.dart';
import '../data/occurrence_outcome_mapper.dart';
import '../domain/level.dart';
import '../domain/level_repository.dart';
import '../domain/performance_record.dart';
import '../domain/performance_record_repository.dart';
import '../domain/score.dart';
import '../domain/score_repository.dart';
import '../domain/streak_repository.dart';
import '../domain/streak_status.dart';
import 'level_engine.dart';
import 'performance_engine.dart';
import 'score_engine.dart';
import 'streak_engine.dart';

class PerformanceController implements OccurrenceOutcomeRecorder {
  PerformanceController({
    required TaskOccurrenceRepository occurrenceRepository,
    required OccurrenceOutcomeMapper mapper,
    required PerformanceEngine performanceEngine,
    required ScoreEngine scoreEngine,
    required LevelEngine levelEngine,
    required StreakEngine streakEngine,
    required PerformanceRecordRepository performanceRecordRepository,
    required ScoreRepository scoreRepository,
    required LevelRepository levelRepository,
    required StreakRepository streakRepository,
    Uuid? uuid,
  })  : _occurrenceRepository = occurrenceRepository,
        _mapper = mapper,
        _performanceEngine = performanceEngine,
        _scoreEngine = scoreEngine,
        _levelEngine = levelEngine,
        _streakEngine = streakEngine,
        _performanceRecordRepository = performanceRecordRepository,
        _scoreRepository = scoreRepository,
        _levelRepository = levelRepository,
        _streakRepository = streakRepository,
        _uuid = uuid ?? const Uuid();

  final TaskOccurrenceRepository _occurrenceRepository;
  final OccurrenceOutcomeMapper _mapper;
  final PerformanceEngine _performanceEngine;
  final ScoreEngine _scoreEngine;
  final LevelEngine _levelEngine;
  final StreakEngine _streakEngine;
  final PerformanceRecordRepository _performanceRecordRepository;
  final ScoreRepository _scoreRepository;
  final LevelRepository _levelRepository;
  final StreakRepository _streakRepository;
  final Uuid _uuid;

  /// Recalcula e persiste o [PerformanceRecord] de um período
  /// (ex.: hoje, últimos 7 dias). Busca as ocorrências agendadas
  /// nesse período, filtra as terminadas via o mapper, calcula e
  /// grava.
  Future<Result<PerformanceRecord>> recalculatePerformance({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final Result<List<TaskOccurrence>> occurrencesResult =
        await _occurrenceRepository.getOccurrencesInRange(
      periodStart,
      periodEnd,
    );
    if (occurrencesResult.isFailure) {
      return Fail<PerformanceRecord>(occurrencesResult.failureOrNull!);
    }

    final outcomes = _mapper.toOutcomes(occurrencesResult.valueOrNull!);

    final record = _performanceEngine.calculate(
      id: _uuid.v4(),
      periodStart: periodStart,
      periodEnd: periodEnd,
      outcomes: outcomes,
      calculatedAt: DateTime.now(),
    );

    return _performanceRecordRepository.saveRecord(record);
  }

  /// Pontua uma única ocorrência já terminada — chamar assim que
  /// o TaskEngine a resolve (COMPLETED/MISSED/DECLINED). Ocorrências
  /// não terminadas são ignoradas: devolve o [Score] atual, sem
  /// gravar nada novo.
  Future<Result<Score>> recordOutcome(TaskOccurrence occurrence) async {
    final outcome = _mapper.toOutcome(occurrence);
    if (outcome == null) {
      return _scoreRepository.getScore();
    }

    final entry = _scoreEngine.entryFor(
      id: _uuid.v4(),
      outcome: outcome,
      occurredAt: DateTime.now(),
    );

    final savedEntry = await _scoreRepository.saveEntry(entry);
    if (savedEntry.isFailure) {
      return Fail<Score>(savedEntry.failureOrNull!);
    }

    final currentScore = await _scoreRepository.getScore();
    if (currentScore.isFailure) {
      return Fail<Score>(currentScore.failureOrNull!);
    }

    final updated = currentScore.valueOrNull!.applyEntry(entry);
    final saveResult = await _scoreRepository.saveScore(updated);
    if (saveResult.isFailure) {
      return Fail<Score>(saveResult.failureOrNull!);
    }

    return Success<Score>(updated);
  }

  /// Implementação de [OccurrenceOutcomeRecorder] — o hook que o
  /// TaskEngine chama best-effort ao resolver uma ocorrência.
  /// Nunca lança: [recordOutcome] já devolve Fail em vez de lançar,
  /// por isso não há nada aqui para capturar.
  @override
  Future<void> onOccurrenceResolved(TaskOccurrence occurrence) async {
    await recordOutcome(occurrence);
  }

  /// Avalia e persiste o nível atual, considerando o score total e
  /// o desempenho recente na janela [recentWindowStart,
  /// recentWindowEnd] (ex.: últimos 7 dias — secção 20: o nível
  /// não depende só do score histórico).
  Future<Result<LevelStatus>> evaluateLevel({
    required DateTime recentWindowStart,
    required DateTime recentWindowEnd,
  }) async {
    final scoreResult = await _scoreRepository.getScore();
    if (scoreResult.isFailure) {
      return Fail<LevelStatus>(scoreResult.failureOrNull!);
    }

    final recentResult = await recalculatePerformance(
      periodStart: recentWindowStart,
      periodEnd: recentWindowEnd,
    );
    if (recentResult.isFailure) {
      return Fail<LevelStatus>(recentResult.failureOrNull!);
    }

    final latestResult = await _levelRepository.getLatest();
    if (latestResult.isFailure) {
      return Fail<LevelStatus>(latestResult.failureOrNull!);
    }

    final previousTier = latestResult.valueOrNull?.tier ?? LevelTier.beginner;

    final evaluation = _levelEngine.evaluate(
      id: _uuid.v4(),
      totalScore: scoreResult.valueOrNull!.total,
      previousTier: previousTier,
      recentPerformance: recentResult.valueOrNull!,
      evaluatedAt: DateTime.now(),
    );

    return _levelRepository.saveEvaluation(evaluation);
  }

  /// Recalcula e persiste o [StreakStatus] a partir das ocorrências
  /// agendadas em [rangeStart, rangeEnd]. [today] evita penalizar o
  /// dia corrente enquanto ainda tiver ocorrências por resolver.
  Future<Result<StreakStatus>> recalculateStreak({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime today,
  }) async {
    final occurrencesResult = await _occurrenceRepository.getOccurrencesInRange(
      rangeStart,
      rangeEnd,
    );
    if (occurrencesResult.isFailure) {
      return Fail<StreakStatus>(occurrencesResult.failureOrNull!);
    }

    final days = _mapper.toDayOutcomes(
      occurrences: occurrencesResult.valueOrNull!,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      today: today,
    );

    final status = _streakEngine.calculate(
      days: days,
      calculatedAt: DateTime.now(),
    );

    final saveResult = await _streakRepository.saveStatus(status);
    if (saveResult.isFailure) {
      return Fail<StreakStatus>(saveResult.failureOrNull!);
    }

    return Success<StreakStatus>(status);
  }
}
