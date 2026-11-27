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

## Fase 4 additions

- `features/alarms/domain/` — `DeclineReason` (as 5 opções de §24),
  `ToleranceChecker` (lógica pura: a janela de tolerância já
  expirou?), `TtsSpeaker` (interface que `TtsService` implementa —
  mesmo padrão do `AlarmNotifier` da Fase 3, para testar sem tocar em
  plugins nativos).
- `features/alarms/infrastructure/tts_service.dart` — o único
  ficheiro que importa `flutter_tts`.
- `features/alarms/application/alarm_ring_controller.dart` —
  `AlarmRingController`: dispara `TaskEngine.triggerOccurrence()`,
  fala a tarefa em voz alta, arma um temporizador que chama
  `markMissed()` automaticamente se a tolerância expirar, e traduz
  Concluída/Adiar/Não-vou nas chamadas correspondentes do
  `TaskEngine`.
- `features/alarms/presentation/` — `AlarmScreen` (o ecrã que toca) e
  `DeclineReasonSheet` (o menu "Não vou, porquê?").
- `TaskEngine` (Fase 2) ganhou `triggerOccurrence()` — só passou a
  fazer sentido agora que existe um ecrã de alarme real a
  disparar SCHEDULED → TRIGGERED.
- Toque na notificação → abre o `AlarmScreen` (`GuiaGoApp` escuta
  `NotificationService.onNotificationTapped` e
  `checkLaunchPayload()`). Ver ADR-008 para a limitação conhecida:
  isto não é um *full-screen intent* — o alarme não aparece
  automaticamente sobre o ecrã bloqueado, precisa de um toque na
  notificação.
```

## Fase 8 additions (MVP)

- Abas: **Tarefas** (criar/editar/apagar, Hoje/Próximas/Concluídas),
  **Calendário** (semana/mês + detalhe, só leitura), **Perfil** editável,
  cartão **OBJETIVO** no Progresso, deslizar de lado entre abas.
- `TaskEngine.editTask` / `removeTask` (apagar = arquivar, ADR-013).
- `SettingsController.saveChange` — grava e só depois publica.
- `features/scheduler`: `AlarmPermissionRequester` (domain),
  `PermissionHandlerAlarmPermissionRequester` (infrastructure),
  `AlarmPermissionPrompter` (application) — pede permissões ao criar a
  primeira tarefa.
- `AlarmRingController` respeita o interruptor de Voz (TTS).
- QA manual: `docs/QA_FASE8_CHECKLIST.md`.

## Fase 9 — Lote H (notificações)

- `features/scheduler/domain`: `NotificationSound`, `AlarmPreferences` +
  `AlarmPreferencesSource`, `AlarmChannelSpec` (um canal Android por
  som+vibração), `AlarmSoundPreviewer`.
- `NotificationService` lê as preferências ao agendar (via
  `SettingsAlarmPreferencesSource`) e implementa também o preview do som.
  `AlarmNotifier` não mudou (os fakes dos testes continuam válidos).
- `AlarmPreferencesApplier`: mudar som/vibração/interruptor rearma (ou cancela)
  os alarmes já agendados, reutilizando o `RecoveryService`.
- Base de dados v6: `settings.notification_sound`, `settings.vibration_enabled`.

## Fase 9 — Lote J (tema)

- `app/theme`: `AppPalette` (dark/light), `AppColors` (getters da paleta ativa),
  `AppTheme.light()/dark()`, `AppThemeMode`, `PaletteScope`, `themeModeProvider`.
- `AppColors` não é `const`; ver ADR-014.
- Base de dados v7: `settings.theme_mode`.

## Fase 9 — Lote K (idioma)

- `lib/l10n`: `AppLocalizations` (abstrata) + `AppLocalizationsPt/En` escritas
  à mão, `AppLanguage`, `languageProvider`; `context.l10n` (fallback PT).
- `MaterialApp.locale` segue `languageProvider`; delegates Material/Cupertino
  via `flutter_localizations`.
- Base de dados v8: `settings.language_code`. Ver ADR-015.

## Fase 9 — Lote P (foto de perfil)

- `features/profile`: `domain/ProfilePhotoStore`, `infrastructure/ImagePickerProfilePhotoStore`,
  `application/profilePhotoStoreProvider`; widgets `ProfileAvatar`, `ProfilePhotoSheet`.
- Base de dados v9: `settings.photo_path` (caminho da cópia dentro da app).

## Fase 9 — fecho

Esquema da base de dados: v9. Colunas novas em `settings` desde a Fase 8:
`notification_sound`, `vibration_enabled` (v6), `theme_mode` (v7),
`language_code` (v8), `photo_path` (v9). Alterar `Settings` ou uma tabela exige
`dart run build_runner build -d`. Relatório completo: `docs/FASE9_RELATORIO.md`.
