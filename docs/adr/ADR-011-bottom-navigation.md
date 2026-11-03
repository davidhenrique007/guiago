# ADR-011 — Bottom navigation with a stateful shell

## Status
Accepted (UI alignment, Lote 2)

## Context
The designs show a bottom bar with five destinations (Início, Tarefas,
Calendário, Progresso, Perfil). The router only had flat routes, and
Home reached the dashboard through an app-bar icon.

## Decision
- `StatefulShellRoute.indexedStack` with five branches; each keeps its
  own stack and state when the user switches tab.
- `AppBottomNav` lives in the design system (custom, flat, bordered),
  `AppShell` in `app/router` wires it to the shell.
- Full-screen flows stay **outside** the shell: `/alarm/:id`,
  `/tasks/create`, onboarding and `/dashboard` (still pushed from the
  Home app bar until the Progress/Insights lote replaces it).
- Destinations without a real screen yet render
  `AppPlaceholderScreen`; Progresso already shows the existing
  `DashboardScreen`.

## Consequences
- Tab order is declared twice (`AppShell.items` and the branches in
  `app_router.dart`); a test guards that the labels exist.
- The Tarefas tab has no list screen yet — it is not assigned to any
  lote and needs a decision.
