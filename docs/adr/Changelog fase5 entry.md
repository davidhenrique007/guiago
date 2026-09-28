## [Unreleased]

### Added — Fase 5: Performance Engine + Gamification
- `features/performance`: `PerformanceEngine`, `ScoreEngine`, `LevelEngine`,
  `StreakEngine`, `PerformanceController`, Drift repositories and providers.
- Drift schema v5: `performance_records`, `score_entries`, `scores`, `levels`,
  `streak_status` (migration `from < 5`).
- `TaskOccurrenceRepository.getOccurrencesInRange(start, end)`.
- `OccurrenceOutcomeRecorder` hook in `TaskEngine` (optional, best-effort).
- ADR-007 (fulfilled day), ADR-008 (scoring and levels).
- 28 new unit tests (suite: 109 passing).