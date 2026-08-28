# ADR-005 — Occurrence State Machine, including where CANCELLED fits

## Status
Accepted (Fase 2)

## Context
Master spec §11 lists the valid transitions:

```
SCHEDULED  -> TRIGGERED
TRIGGERED  -> COMPLETED
TRIGGERED  -> SNOOZED
TRIGGERED  -> DECLINED
TRIGGERED  -> MISSED
SNOOZED    -> SCHEDULED
```

`CANCELLED` is listed as one of the seven states (§11) but has no
transition into it in that list, which would make it unreachable.

## Decision
`OccurrenceStateMachine` implements exactly the six transitions
above, plus two more into `CANCELLED`:

```
SCHEDULED -> CANCELLED
SNOOZED   -> CANCELLED
```

Reasoning: `CANCELLED` needs *some* way to be reached (e.g. the
parent task gets archived or deleted while an occurrence is still
pending), and `SCHEDULED`/`SNOOZED` are the only non-terminal states
that make sense as a cancellation source — `TRIGGERED` already has
its own defined outcomes (completed/snoozed/declined/missed).

`TRIGGERED`, `COMPLETED`, `DECLINED`, `MISSED`, and `CANCELLED` are
terminal in the code (`OccurrenceStateMachine.isTerminal`) except
`TRIGGERED`, which resolves to one of the four outcomes above.

`TaskEngine` never sets a `TaskOccurrence.status` field directly —
every change goes through `OccurrenceStateMachine.transition()`,
which returns `Result<OccurrenceStatus>` and fails closed on any
transition not in the table above.

## Consequences
- `CANCELLED` is reachable, so no dead state in the enum.
- Fase 3 (Scheduler) will be the first caller to move
  `SCHEDULED -> TRIGGERED`, when an alarm actually fires. Fase 2's
  `TaskEngine` has no `triggerOccurrence()` method — that
  responsibility belongs to the Scheduler, not the Task Engine
  (master spec §17 doesn't list it as a Task Engine responsibility).
