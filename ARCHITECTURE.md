```markdown
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

## Fase 1 additions

- `design_system/` — the component library (`AppButton`, `AppCard`,
  `AppTextField`, `AppProgress`, `AppBadge`, `AppDialog`,
  `AppBottomSheet`, `AppEmptyState`, `AppLoadingState`,
  `AppErrorState`), exported through a single
  `design_system/design_system.dart` barrel. Typography now runs on
  Manrope (Google Fonts) instead of the Fase 0 placeholder.
- `features/onboarding/` — `Settings` domain entity, Drift-backed
  `SettingsRepository`, `OnboardingController` (Riverpod
  `AsyncNotifier`), and the Splash → Welcome → Onboarding (5 steps:
  Perfil, Objetivo, Janela do dia, Notificações/TTS,
  Snooze/Tolerância) → Home flow. See ADR-003 for why `Settings`
  currently lives under `onboarding` rather than `features/settings`.

## Fase 2 additions

- `features/tasks/domain/` — `Task`, `TaskOccurrence`, `TaskEvent`
  entities; `RecurrenceRule` (Freezed sealed union: none/daily/
  weekly/customDays); `OccurrenceStateMachine` (pure, §11);
  `RecurrenceEngine` (pure, §12 — generates one occurrence at a
  time, never a batch). See ADR-004 and ADR-005.
- `features/tasks/data/` — `DriftTaskRepository`,
  `DriftTaskOccurrenceRepository`, `DriftTaskEventRepository`, and
  the Riverpod providers wiring them plus `TaskEngine`.
- `features/tasks/application/task_engine.dart` — `TaskEngine`
  (§17): `createTask`, `updateTask`, `archiveTask`, `deleteTask`,
  `completeOccurrence`, `declineOccurrence`, `snoozeOccurrence`,
  `markMissed`. Every occurrence status change goes through
  `OccurrenceStateMachine`; every terminal resolution asks
  `RecurrenceEngine` for the task's next occurrence if it recurs.
- No UI in this phase — Fase 2 is domain/data/application only, per
  the master spec's own phase scope (Task Creation UX and the
  Dashboard are later phases).
- Database: `tasks`, `task_occurrences`, `task_events` tables added
  (schemaVersion 2 → 3), with foreign keys from occurrences/events
  back to `tasks`, and indexes on the foreign-key columns.

## Fase 3 additions

- `features/scheduler/domain/` — `AlarmRecord` (keyed by
  `occurrenceId`, 1:1 with an occurrence), `AlarmRepository`,
  `AlarmIdGenerator` (pure djb2 hash → stable native alarm int ID),
  `AlarmNotifier` (interface `NotificationService` implements — keeps
  every test off platform channels).
- `features/tasks/domain/alarm_scheduler.dart` — the interface
  `TaskEngine` calls; implemented by `SchedulerEngine`. Lives in
  `tasks/domain`, not `scheduler/domain`, on purpose — see ADR-006
  for why (keeps the dependency one-directional: scheduler → tasks).
- `features/scheduler/infrastructure/notification_service.dart` —
  the only file that imports `flutter_local_notifications`. Handles
  init, the Android notification channel, permission requests
  (`permission_handler`), and timezone-aware scheduling via the
  `timezone` package + `flutter_timezone` (device's real IANA zone —
  see ADR-007).
- `features/scheduler/application/scheduler_engine.dart` —
  `SchedulerEngine` (§13): `scheduleOccurrence`, `cancelOccurrence`,
  `reschedule`, `rescheduleAll` (the engine-level foundation for
  Fase 7's boot recovery).
- `features/scheduler/data/` — `DriftAlarmRepository` and the
  Riverpod providers, including `taskEngineWithSchedulerProvider`
  (a `TaskEngine` with the scheduler wired in — the plain
  `taskEngineProvider` from the tasks feature stays scheduler-free).
- `TaskEngine` (Fase 2) now takes an optional `AlarmScheduler?` —
  every Fase 2 test still passes unchanged with it left `null`.
  When provided: task creation schedules the first occurrence's
  alarm; completing/declining/missing an occurrence cancels its
  alarm and schedules the next one if the task recurs; snoozing
  cancels the old alarm and schedules the new time.
- Database: `alarm_records` table added (schemaVersion 3 → 4).
- Native manual step required (not generated by this project's
  files): `AndroidManifest.xml` needs `POST_NOTIFICATIONS` and
  `SCHEDULE_EXACT_ALARM` permissions added by hand.
```