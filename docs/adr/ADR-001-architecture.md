# ADR-001 — Layered architecture

## Status
Accepted (Fase 0)

## Context
GuiaGo needs to stay offline-first, testable, and swappable at its
edges (database, notifications, future AI providers) without ever
letting those concerns leak into business rules.

## Decision
Adopt a 5-layer structure:

```
Presentation → Application → Domain → Data → Infrastructure
```

- **Domain** has zero dependency on Flutter, SQLite/Drift, or any AI
  provider. It only knows entities, value objects, business rules,
  engines, and state machines.
- **Data** implements repositories backed by Drift.
- **Infrastructure** wraps native concerns (alarms, notifications,
  TTS, platform channels).
- **Application** orchestrates use cases/controllers and is the only
  layer allowed to depend on both Domain and Data/Infrastructure
  abstractions.
- **Presentation** (screens/widgets) never contains business rules or
  raw SQL.

## Consequences
- Slightly more files/boilerplate for simple features.
- Domain logic is unit-testable without a Flutter widget test harness
  or a real database.
- Swapping Drift for something else later, or adding a remote data
  source (Fase "SaaS"), touches Data/Infrastructure only.
