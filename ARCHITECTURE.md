# Architecture

```
Presentation
      ↓
Application
      ↓
Domain
      ↓
Data
      ↓
Infrastructure
```

- **Domain** never imports Flutter, Drift, or any AI SDK. Pure Dart:
  entities, value objects, business rules, engines, state machines.
- **Data** — repositories, Drift DAOs/tables, mappers.
- **Infrastructure** — alarms, notifications, TTS, platform channels,
  native APIs.
- **Application** — use cases, controllers, Riverpod providers,
  commands. The only layer allowed to see both Domain and
  Data/Infrastructure.
- **Presentation** — screens, widgets, UI state only. No SQL, no
  business rules.

## Project layout

```
lib/
├── app/            # app shell: router, theme, config
├── core/           # cross-cutting: errors, result, constants, utils, services
├── features/       # one folder per feature (empty until its phase lands)
└── main.dart

test/
├── core/
├── features/
└── integration/

docs/
├── adr/            # architecture decision records
```

## Current state (Fase 0)

Only the foundation exists:

- `core/result/result.dart` + `core/errors/failures.dart` — the
  `Result<T>` / `Failure` pattern used everywhere once Fase 2+ lands.
- `core/services/app_database.dart` — Drift wired with a single
  bookkeeping table (`app_metadata`). No domain tables yet — those
  belong to the phase that owns that domain.
- `app/theme/*` — design tokens (colors, typography, spacing, motion)
  and the assembled `ThemeData`.
- `app/router/*` — GoRouter with a single placeholder route.
- `app/config/app_environment.dart` — the first Freezed model,
  proving codegen is wired correctly.

Everything under `lib/features/*` is intentionally empty. See
[README.md](README.md) for the phase roadmap.
