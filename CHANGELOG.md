# Changelog

## [Unreleased] — Fase 0: Foundation + Architecture

### Added
- Project scaffold: `app/`, `core/`, `features/*` (empty), `test/`.
- Dependencies: Riverpod, GoRouter, Freezed, Drift, uuid, timezone,
  flutter_local_notifications, flutter_tts, permission_handler, dio
  (reserved for future SaaS sync).
- `Result<T>` + sealed `Failure` taxonomy (`core/result`,
  `core/errors`).
- Drift `AppDatabase` with a single `app_metadata` bookkeeping table
  (no domain tables yet).
- Design system foundation: `AppColors`, `AppTypography`,
  `AppSpacing`, `AppRadius`, `AppDurations`, `AppCurves`,
  `AppTheme.light()`.
- GoRouter with a placeholder route, wired into `GuiaGoApp`.
- `AppEnvironment` (Freezed) proving codegen is correctly wired.
- Lint config (`flutter_lints` + stricter analyzer options).
- CI workflow (format, analyze, test).
- ADR-001 (layered architecture), ADR-002 (Result/Failure pattern).
- Unit tests for `Result<T>` and `Failure`; smoke widget test for
  app boot.

## [Unreleased] — Fase 1: Design System + Onboarding

### Added
- `google_fonts` dependency; typography now uses Manrope instead of
  the Fase 0 Roboto placeholder.
- Design system component library: `AppButton`, `AppCard`,
  `AppTextField`, `AppProgress`, `AppBadge`, `AppDialog`,
  `AppBottomSheet`, `AppEmptyState`, `AppLoadingState`,
  `AppErrorState` — exported via `design_system/design_system.dart`.
- `Settings` domain entity + Drift `settings` table (single row) +
  `SettingsRepository` (interface + Drift implementation).
- `OnboardingController` (Riverpod `AsyncNotifier<Settings>`):
  loads/saves settings, exposes per-field update methods, and
  `complete()` to persist with `onboardingCompleted = true`.
- Screens: `SplashScreen` (loads settings, routes to Welcome or
  Home), `WelcomeScreen`, `OnboardingScreen` (5-step `PageView` with
  progress bar and Voltar/Continuar/Concluir controls).
- Onboarding steps: Perfil (nome), Objetivo principal, Janela do dia
  (horário início/fim), Notificações/TTS, Snooze/Tolerância padrão.
- Router: `/` (Splash), `/welcome`, `/onboarding`, `/home` — Fase 0's
  placeholder Home now lives at `/home`.
- ADR-003 (Settings ownership).
- Tests: `DriftSettingsRepository` round-trip, `OnboardingController`
  (initial state, field updates, `complete()`), `OnboardingScreen`
  (step navigation, back button, full completion flow to Home), and
  an updated app smoke test for the Splash → Welcome flow.
- `test/flutter_test_config.dart` — disables `google_fonts` runtime
  network fetching during tests.

## [Unreleased] — Fase 2: Task Engine + Recurrence Engine

### Added
- Domain: `Task`, `TaskOccurrence`, `TaskEvent`, `TaskPriority`,
  `OccurrenceStatus`, `RecurrenceRule` (Freezed sealed union:
  none/daily/weekly/customDays).
- `OccurrenceStateMachine` — validates every occurrence status
  transition (§11); `CANCELLED` is reachable from
  `scheduled`/`snoozed` (see ADR-005).
- `RecurrenceEngine` — computes the task's next occurrence one at a
  time, never a batch (§12, see ADR-004).
- `TaskEngine` (Application layer, §17): `createTask`, `updateTask`,
  `archiveTask`, `deleteTask`, `completeOccurrence`,
  `declineOccurrence`, `snoozeOccurrence`, `markMissed`.
- Data: `DriftTaskRepository`, `DriftTaskOccurrenceRepository`,
  `DriftTaskEventRepository`, plus Riverpod providers
  (`task_providers.dart`).
- Database: `tasks`, `task_occurrences`, `task_events` tables
  (schemaVersion 2 → 3), with foreign keys and indexes.
- ADR-004 (Recurrence Engine), ADR-005 (Occurrence State Machine).
- Tests: `OccurrenceStateMachine` (every documented transition, plus
  rejection of invalid ones and terminal-state lockout),
  `RecurrenceEngine` (none/daily/weekly/customDays, including week
  wraparound), all three Drift repositories (round-trip, filtering,
  ordering, foreign-key-linked fixtures), and `TaskEngine`
  (creation, completion with/without recurrence, decline with
  reason, snooze reschedule + event log, and invalid-transition
  rejection — including the case of completing a still-SCHEDULED
  occurrence, since only TRIGGERED can resolve).
- No UI in this phase — see ARCHITECTURE.md for why.
