# ADR-007: Definition of a "fulfilled day" (Streak Engine)

- Status: Accepted
- Phase: 5 (Performance Engine + Gamification)
- Related: master spec §21, `DayOutcome`, `StreakEngine`, `OccurrenceOutcomeMapper.toDayOutcomes`

## Context

The spec requires `currentStreak` and `longestStreak` and demands that the
definition of a "fulfilled day" be documented and free of timezone bugs.

## Decision

Each calendar day (local time, normalized to midnight) is classified as:

| Class       | Rule                                                                 |
|-------------|----------------------------------------------------------------------|
| `fulfilled` | At least 1 non-cancelled occurrence scheduled that day, and ALL of them ended `completed`. |
| `broken`    | At least 1 non-cancelled occurrence scheduled that day, and at least one ended `missed`, `declined`, or is stale-unresolved. |
| `neutral`   | No occurrences that day, or only `cancelled` ones.                   |

Streak rules:
- `fulfilled` extends the running streak.
- `broken` resets it to 0.
- `neutral` neither extends nor breaks it (free days do not punish the user).
- `longestStreak` is the maximum running streak ever reached.
- **Today** is classified `neutral` while it still has unresolved
  (`scheduled`/`triggered`/`snoozed`) occurrences, so the user is never
  penalized before the day is over.

A day is attributed by the occurrence's `scheduledAt` in local time
(a snoozed occurrence keeps counting on the day it is currently scheduled).

## Consequences

- `declined` breaks the day, same as `missed` (consistent with the −5/−5
  scoring in `ScoringPolicy`). If the product later wants "declined with a
  valid reason" to be neutral, only `OccurrenceOutcomeMapper.toDayOutcomes`
  changes — the engine does not.
- Day classification lives in the Data layer (mapper), the engine only
  consumes `DayOutcome`; the Domain stays free of timezone logic.