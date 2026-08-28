# ADR-004 — Recurrence Engine generates one occurrence at a time

## Status
Accepted (Fase 2)

## Context
Master spec §12 requires: "Nunca gerar ocorrências infinitamente.
Utilizar geração controlada" — and describes the flow as `Occorrência
atual → Resultado → Recurrence Engine → Próxima ocorrência →
Scheduler`.

## Decision
`RecurrenceEngine.nextOccurrenceAfter()` is a pure function that
computes exactly one `DateTime?` (or `null` for `RecurrenceRule.none`)
given the task's rule, its original anchor time, and a reference
point ("after"). It never returns a list or a range.

`TaskEngine` only calls it once, at the moment an occurrence resolves
(completed/declined/missed) — never speculatively, never in a batch.
A task therefore has at most one non-terminal ("live") occurrence in
the database at any time.

Four rule variants (`none`, `daily`, `weekly`, `customDays`) are
modeled as a Freezed sealed union, matched with Dart 3 `switch`
patterns rather than Freezed's generated `when()`/`map()` — sealed-
class `switch` needs no generated convenience method to work, so it
isn't affected by codegen/version churn the way `when()` was earlier
in this project (see the Fase 1 build log).

`weekly` intentionally has no explicit weekday field — it repeats on
whatever weekday the anchor date falls on. `customDays` always
carries an explicit `Set<int>` of weekdays. This mirrors the two
being presented as distinct options during Task Creation UX (§23),
even though both could technically be represented as
`customDays({anchor.weekday})`.

## Consequences
- No risk of runaway occurrence generation — there is structurally
  nowhere in the code that could produce more than one occurrence
  per resolution.
- The Scheduler (Fase 3) will call into `TaskEngine`, not directly
  into `RecurrenceEngine` — it never needs to know the recurrence
  rules itself.
