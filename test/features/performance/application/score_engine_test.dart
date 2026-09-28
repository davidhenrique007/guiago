import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/performance/application/score_engine.dart';
import 'package:guiago/features/performance/domain/occurrence_outcome.dart';
import 'package:guiago/features/performance/domain/score.dart';
import 'package:guiago/features/performance/domain/scoring_policy.dart';

void main() {
  const engine = ScoreEngine();

  group('ScoreEngine.reasonFor', () {
    test('completed without a snooze is ScoringReason.completed', () {
      const outcome = OccurrenceOutcome(
        occurrenceId: 'o1',
        status: OutcomeStatus.completed,
        snoozeCount: 0,
      );
      expect(engine.reasonFor(outcome), ScoringReason.completed);
    });

    test(
      'completed after a snooze is ScoringReason.completedAfterSnooze',
      () {
        const outcome = OccurrenceOutcome(
          occurrenceId: 'o2',
          status: OutcomeStatus.completed,
          snoozeCount: 2,
        );
        expect(engine.reasonFor(outcome), ScoringReason.completedAfterSnooze);
      },
    );

    test('missed and declined map directly', () {
      const missed = OccurrenceOutcome(
        occurrenceId: 'o3',
        status: OutcomeStatus.missed,
        snoozeCount: 0,
      );
      const declined = OccurrenceOutcome(
        occurrenceId: 'o4',
        status: OutcomeStatus.declined,
        snoozeCount: 0,
      );
      expect(engine.reasonFor(missed), ScoringReason.missed);
      expect(engine.reasonFor(declined), ScoringReason.declined);
    });
  });

  group('ScoreEngine.entryFor', () {
    test('uses the default policy points', () {
      const outcome = OccurrenceOutcome(
        occurrenceId: 'o1',
        status: OutcomeStatus.completed,
        snoozeCount: 0,
      );
      final occurredAt = DateTime(2026, 1, 1, 8);

      final entry = engine.entryFor(
        id: 'e1',
        outcome: outcome,
        occurredAt: occurredAt,
      );

      expect(entry.id, 'e1');
      expect(entry.occurrenceId, 'o1');
      expect(entry.reason, ScoringReason.completed);
      expect(entry.points, 10);
      expect(entry.occurredAt, occurredAt);
    });

    test('respects a custom policy', () {
      const customPolicy = ScoringPolicy(
        points: {
          ScoringReason.completed: 100,
          ScoringReason.completedAfterSnooze: 50,
          ScoringReason.missed: -20,
          ScoringReason.declined: -20,
        },
      );
      const customEngine = ScoreEngine(policy: customPolicy);
      const outcome = OccurrenceOutcome(
        occurrenceId: 'o1',
        status: OutcomeStatus.missed,
        snoozeCount: 0,
      );

      final entry = customEngine.entryFor(
        id: 'e2',
        outcome: outcome,
        occurredAt: DateTime(2026, 1, 1),
      );

      expect(entry.points, -20);
    });
  });

  group('ScoreEngine.applyAll', () {
    test(
      'applies entries in chronological order regardless of input order',
      () {
        final current = Score(total: 0, updatedAt: DateTime(2026, 1, 1));
        final earlier = ScoreEntry(
          id: 'e1',
          occurrenceId: 'o1',
          reason: ScoringReason.completed,
          points: 10,
          occurredAt: DateTime(2026, 1, 1, 8),
        );
        final later = ScoreEntry(
          id: 'e2',
          occurrenceId: 'o2',
          reason: ScoringReason.missed,
          points: -5,
          occurredAt: DateTime(2026, 1, 1, 20),
        );

        // Passadas fora de ordem de propósito.
        final result = engine.applyAll(current, [later, earlier]);

        expect(result.total, 5);
        expect(result.updatedAt, later.occurredAt);
      },
    );
  });
}
