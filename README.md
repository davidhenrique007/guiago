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
**Fase 3 — Scheduler + Alarm System** ✅
**Fase 4 — TTS + Snooze + Tolerance** ✅ scaffolded, pending local verification (see "Getting started" below).

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test