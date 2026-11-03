# ADR-010 — Visual identity: dark-first palette and three type voices

## Status
Accepted (UI alignment, Lote 1)

## Context
Phases 0–6 shipped a light placeholder palette (`AppColors` said so
in its own doc comment) and Manrope typography. The approved screen
designs (Nova tarefa, Calendário, Progresso, Alarme, Insights) use a
dark emerald-on-near-black identity with serif titles and monospace
figures. Master spec §7 asks for a premium identity that is not a
generic Flutter theme.

## Decision
- A single **dark** theme (`AppTheme.dark()`); there is no light mode
  and no mode switch. It is part of the identity.
- `AppColors` keeps every existing token name and changes its values,
  so screens re-theme without edits. New tokens: `backgroundVoid`,
  `borderSoft`, `textTertiary`.
- `textTertiary` is decorative only: it does not reach WCAG AA on
  `surface`. Labels and captions the user must read use
  `textSecondary` (master spec §28).
- Typography has three voices: Fraunces (display/titles), IBM Plex
  Sans (body/buttons), IBM Plex Mono (labels, times, figures).
- New tokens/components: `AppRadius.field` / `AppRadius.xl`,
  `AppElevation`, `AppTaskCard`.

## Consequences
- Every screen changes look at once; behavior is untouched.
- The alarm screen got a minimal contrast fix (it used the primary
  color as background) and is fully restyled in a later lote.
- `AppTheme.light()` was removed (it had a single caller).
