# ADR-008: Scoring policy and level evaluation

- Status: Accepted (values are tunable defaults)
- Phase: 5 (Performance Engine + Gamification)
- Related: master spec §18–§20, `ScoringPolicy`, `LevelPolicy`, `ScoreEngine`, `LevelEngine`

## Scoring

All points live in `ScoringPolicy` (never scattered in code):

| Reason                  | Points |
|-------------------------|--------|
| `completed`             | +10    |
| `completedAfterSnooze`  | +5     |
| `missed`                | −5     |
| `declined`              | −5     |

`completedAfterSnooze` is derived (`completed` with `snoozeCount > 0`); it is
not a state-machine state (§11). Every scored occurrence appends an immutable
`ScoreEntry` (ledger); `Score` is the aggregate and can be rebuilt from the
ledger (`ScoreEngine.applyAll`).

## Levels

`LevelPolicy` maps total score to a tier: beginner (0), consistent (100),
disciplined (300), elite (700).

Per §20 the level must not depend only on historical score. Rule: if the
recent-window `completionRate` is below `recentCompletionRateFloor` (0.5),
the tier is capped one level below what the score alone indicates (never
below beginner). A window with no occurrences does not penalize.

## Consequences

- Thresholds/points are placeholders: change them only in the policies.
- Scoring is event-driven: `TaskEngine` reports every terminal resolution via
  `OccurrenceOutcomeRecorder` (best-effort, same inversion pattern as
  `AlarmScheduler`, ADR-006). Performance/streak/level are recalculated on
  demand from `getOccurrencesInRange`.