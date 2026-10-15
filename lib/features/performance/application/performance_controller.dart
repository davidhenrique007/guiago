// GuiaGo — Fase 5: Performance Engine + Gamification
// PerformanceController
//
// Orquestra o mapper + os 4 engines + os 4 repositories desta
// fase (e o TaskOccurrenceRepository da Fase 2, via
// getOccurrencesInRange). É o único ponto que o resto da app
// precisa de chamar para ESCREVER estado de desempenho.
// (Leituras para o Dashboard passam pelo DashboardService.)
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

  /// Janela (em dias) usada para o desempenho "recente" do nível.
  static const int _recentWindowDays = 7;

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

  /// Recalcula e PERSISTE o [PerformanceRecord] de um período.
  /// Cada chamada grava uma linha nova — não usar em leituras de UI.
  Future<Result<PerformanceRecord>> recalculatePerformance({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final computed = await _calculatePerformance(
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    if (computed.isFailure) return computed;
    return _performanceRecordRepository.saveRecord(computed.valueOrNull!);
  }

  /// Pontua uma única ocorrência já terminada (COMPLETED/MISSED/
  /// DECLINED). Ocorrências não terminadas são ignoradas: devolve o
  /// [Score] atual, sem gravar nada novo.
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

  /// Hook chamado (best-effort) pelo TaskEngine quando uma
  /// ocorrência termina. Por ordem: pontua, atualiza o streak
  /// (histórico completo) e reavalia o nível (janela recente).
  /// Cada passo é independente — uma falha não impede os seguintes,
  /// e o TaskEngine nunca vê exceções.
  @override
  Future<void> onOccurrenceResolved(TaskOccurrence occurrence) async {
    await recordOutcome(occurrence);

    final DateTime now = DateTime.now();
    await recalculateStreak(rangeEnd: now, today: now);
    await evaluateLevel(
      recentWindowStart: DateTime(
        now.year,
        now.month,
        now.day - (_recentWindowDays - 1),
      ),
      recentWindowEnd: now,
    );
  }

  /// Avalia o nível (score total + desempenho recente, secção 20).
  /// O histórico `levels` só regista MUDANÇAS de nível (e a primeira
  /// avaliação) — se o tier não mudou, devolve a avaliação anterior
  /// sem gravar nada.
  Future<Result<LevelStatus>> evaluateLevel({
    required DateTime recentWindowStart,
    required DateTime recentWindowEnd,
  }) async {
    final scoreResult = await _scoreRepository.getScore();
    if (scoreResult.isFailure) {
      return Fail<LevelStatus>(scoreResult.failureOrNull!);
    }

    final recentResult = await _calculatePerformance(
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
    final LevelStatus? latest = latestResult.valueOrNull;

    final evaluation = _levelEngine.evaluate(
      id: _uuid.v4(),
      totalScore: scoreResult.valueOrNull!.total,
      previousTier: latest?.tier ?? LevelTier.beginner,
      recentPerformance: recentResult.valueOrNull!,
      evaluatedAt: DateTime.now(),
    );

    if (latest != null && latest.tier == evaluation.tier) {
      return Success<LevelStatus>(latest);
    }
    return _levelRepository.saveEvaluation(evaluation);
  }

  /// Recalcula e persiste o [StreakStatus]. Com [rangeStart] nulo usa
  /// o histórico completo (desde a ocorrência mais antiga), para que
  /// `longestStreak` não fique limitado a uma janela. [today] evita
  /// penalizar o dia corrente enquanto ainda tiver ocorrências por
  /// resolver.
  Future<Result<StreakStatus>> recalculateStreak({
    DateTime? rangeStart,
    required DateTime rangeEnd,
    required DateTime today,
  }) async {
    final occurrencesResult = await _occurrenceRepository.getOccurrencesInRange(
      rangeStart ?? DateTime.fromMillisecondsSinceEpoch(0),
      rangeEnd,
    );
    if (occurrencesResult.isFailure) {
      return Fail<StreakStatus>(occurrencesResult.failureOrNull!);
    }
    final occurrences = occurrencesResult.valueOrNull!;

    final days = _mapper.toDayOutcomes(
      occurrences: occurrences,
      rangeStart: rangeStart ?? _earliestDay(occurrences) ?? today,
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

  /// Calcula (sem gravar) o desempenho de um período.
  Future<Result<PerformanceRecord>> _calculatePerformance({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final occurrencesResult = await _occurrenceRepository.getOccurrencesInRange(
      periodStart,
      periodEnd,
    );
    if (occurrencesResult.isFailure) {
      return Fail<PerformanceRecord>(occurrencesResult.failureOrNull!);
    }

    final outcomes = _mapper.toOutcomes(occurrencesResult.valueOrNull!);

    return Success<PerformanceRecord>(
      _performanceEngine.calculate(
        id: _uuid.v4(),
        periodStart: periodStart,
        periodEnd: periodEnd,
        outcomes: outcomes,
        calculatedAt: DateTime.now(),
      ),
    );
  }

  DateTime? _earliestDay(List<TaskOccurrence> occurrences) {
    DateTime? earliest;
    for (final TaskOccurrence occurrence in occurrences) {
      if (earliest == null || occurrence.scheduledAt.isBefore(earliest)) {
        earliest = occurrence.scheduledAt;
      }
    }
    if (earliest == null) return null;
    return DateTime(earliest.year, earliest.month, earliest.day);
  }
}
