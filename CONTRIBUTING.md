# Contributing

## Branches

- `main` — always releasable.
- `develop` — integration branch.
- `feature/*`, `fix/*`, `release/*` — work branches.

## Before opening a PR

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

All three must pass — CI enforces the same checks.

## Rules (per the GuiaGo master spec)

- Domain code never imports Flutter, Drift, or an AI SDK.
- No `catch (_) {}` — use `Result<T>` / `Failure` instead.
- No business logic in widgets. No raw SQL in widgets.
- One phase at a time — don't implement a later phase's scope ahead
  of schedule, even if it seems convenient.
- Record any non-obvious architectural decision as a new ADR in
  `docs/adr/`.
