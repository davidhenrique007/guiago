```markdown
# GuiaGo

> Organize. Aja. Avance.

Personal productivity, execution, accountability and behavioral
intelligence app. Offline-first, modular, built to evolve from a
local MVP into a SaaS + AI-assisted product.

This repository follows the GuiaGo master engineering spec: 9 build
phases (Fase 0 → Fase 8), one phase at a time, with a checkpoint
(format + analyze + tests) before advancing to the next.

## Status

**Fase 0 — Foundation + Architecture** ✅
**Fase 1 — Design System + Onboarding** ✅
**Fase 2 — Task Engine + Recurrence Engine** ✅
**Fase 3 — Scheduler + Alarm System** ✅ scaffolded, pending local verification (see "Getting started" below).

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Run the app:

```bash
flutter run
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) and [docs/adr](docs/adr) for
the layered architecture and the decisions behind it.

## Roadmap

| Fase | Escopo |
|---|---|
| 0 | Foundation + Architecture | ✅ |
| 1 | Design System + Onboarding | ✅ |
| 2 | Task Engine + Recurrence Engine | ✅ |
| 3 | Scheduler + Alarm System | ✅ |
| 4 | TTS + Snooze + Tolerance | ⏳ |
| 5 | Performance Engine + Gamification | ⏳ |
| 6 | Dashboard + Analytics | ⏳ |
| 7 | Reliability + Offline Recovery | ⏳ |
| 8 | Production QA + MVP Release | ⏳ |
```