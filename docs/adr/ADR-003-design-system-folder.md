# ADR-003 — Dedicated `lib/design_system/` for shared UI components

## Status
Accepted (Fase 1)

## Context
Master spec §6 lists `app/`, `core/`, `features/` as the top-level
`lib/` folders and doesn't name a home for shared components
(AppButton, AppCard, AppTextField, etc. — §7). `core/` is reserved
for non-Flutter cross-cutting concerns (errors, result, constants,
utils, extensions, services) per ADR-001, so putting widgets there
would blur that boundary. `app/` is the app shell (router, theme,
config), not a place for a growing component library either.

## Decision
Add a new top-level folder, `lib/design_system/`:

```
design_system/
├── tokens/       # re-exports of app/theme/* for a single import surface
└── components/   # AppButton, AppCard, AppTextField, AppProgress,
                  # AppBadge, AppDialog, AppBottomSheet,
                  # AppEmptyState, AppLoadingState, AppErrorState
```

`AppTaskCard` is intentionally NOT included yet — it depends on the
`Task` entity, which doesn't exist until Fase 2. Adding it now would
mean inventing Task fields ahead of the phase that owns them.

## Consequences
- Any screen imports one `design_system.dart` barrel file instead of
  reaching into `app/theme/*` directly.
- Slightly deviates from the literal folder list in §6; documented
  here per the master spec's own rule (§38: record decisions as
  ADRs) rather than silently diverging.
