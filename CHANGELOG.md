<!-- Colar no CHANGELOG.md a seguir à secção da Fase 3 (ou da última fase que já lá estiver). Sem cercas ``` à volta. -->

## [Unreleased] — UI alignment (Lotes 1–2)

### Changed
- Dark theme from the approved designs: new `AppColors` values,
  Fraunces / IBM Plex typography, `AppTheme.dark()` replaces
  `AppTheme.light()`.
- `AppCard`, `AppButton`, `AppTextField`, `AppProgress` restyled.
- Home "Hoje" list uses `AppTaskCard`.
- Alarm screen: background/text colors fixed for the dark theme.
- Router: five-branch `StatefulShellRoute` with a bottom bar.

### Added
- `AppTaskCard`, `AppBottomNav`, `AppElevation`, `AppRadius.field/xl`.
- `AppShell`, `AppPlaceholderScreen`.
- ADR-010 (visual identity), ADR-011 (bottom navigation).
- Tests for `AppTaskCard`, `AppBottomNav` and the shell.

## [Unreleased] — UI alignment (Lote 3: Calendário)

### Added
- Calendar tab: Monday–Sunday week strip, long date label and the
  day's occurrences (`CalendarService`, `CalendarController` family
  keyed by local midnight, `CalendarScreen`). Shows only persisted
  occurrences — future recurrences are not projected (spec §12).
- `PtDateLabels` (`core/utils`): shared Portuguese weekday/month names.
- Tests: `CalendarService`, week strip, `CalendarScreen`, `PtDateLabels`.

### Changed
- `HomeGreeting` uses `PtDateLabels`; its text is unchanged.
- Router: Calendar branch uses `CalendarScreen` instead of the placeholder.

## [Unreleased] — UI alignment (Lote 4: Progresso + Insights)

### Added
- "Meu progresso" (Progresso tab): completion ring, streak, level card
  with "Faltam X pontos para <nível>" and the trend chart. Default
  period is now Semana.
- `NextLevelProgress` (pure) + `DashboardSnapshot.nextTier /
  pointsToNextTier / nextTierProgress`, computed in `DashboardService`
  (new optional `policy` parameter, default `LevelPolicy.defaultPolicy`).
  Nothing is shown for the top tier or when recent performance holds
  the level back (0 or negative gap).
- `LevelTierLabel` extension (`performance/presentation`), shared.
- Insights (`/profile/insights`): summary, best productivity hours
  (`ProductivityEngine`, 3 consecutive hours, minimum 10 completions)
  and top 3 completed tasks (`InsightsService`, `InsightsPolicy`).
  The link from Perfil arrives with Lote 5.
- `AppTrendChart`: optional `highlightedIndices` and `dimColor`
  (defaults keep the previous look).

### Removed
- `/dashboard` route and the insights icon on the Home app bar (the
  Progresso tab replaces them).
- `DashboardMetricsGrid` (replaced by the three progress cards).
- Duplicate `dashboard/application/dashboard_providers.dart` (nothing
  imported it; the controller uses `dashboard/data/`).

### Tests
- Updated: `home_screen_test`, `dashboard_screen_test`,
  `dashboard_service_test`. New: `NextLevelProgress`,
  `ProductivityEngine`, `InsightsService`, `InsightsScreen`,
  `AppTrendChart`.

## [Unreleased] — UI alignment (Lotes 5–6: Perfil, Nova tarefa, Alarme)

### Added
- Perfil tab (`ProfileScreen`): avatar initial, name and objective,
  a card linking to Insights (`/profile/insights`) and the read-only
  preferences from onboarding. Editing them is not in this roadmap.
- `SettingsController` (`onboarding/application`): read access to
  `Settings` for screens outside onboarding.
- Nova tarefa: Tolerância and Snooze padrão chips, starting at the
  values saved in `Settings` and passed to `TaskEngine.createTask`.
- `AppButton`: `caution` (amber) and `danger` (coral) variants.
- `PtDateLabels.time` and `PtDateLabels.dayAndMonthUpper`.

### Changed
- Nova tarefa: description right after the title; priority chips in
  Portuguese (Baixa / Média / Alta); button reads "Guardar tarefa".
- Alarm screen: amber bell, "Está na hora de", time and date,
  "Adiar N min" (the task's snooze), "Não vou fazer" and the
  tolerance footer. Behaviour is unchanged.
- Router: Perfil branch uses `ProfileScreen`.

### Tests
- Updated: `alarm_screen_test`, `task_create_screen_test` (taller
  viewport, new button label), `pt_date_labels_test`.
- New: `ProfileScreen`, `SettingsController`, `AppButton`.

## [Unreleased] — Fase 7: Reliability + Offline Recovery

### Added
- `RecoveryService` (`features/recovery`): on app start and on return to the
  foreground it resolves occurrences whose tolerance already closed (missed,
  through `TaskEngine`), re-arms the alarms of live occurrences and notifies
  right away for overdue ones still inside their tolerance.
- `OverdueClassifier`, `RecoveryPolicy`, `RecoveryAction`, `RecoveryReport`.
- `AlarmPermissionChecker` + `PermissionHandlerAlarmPermissionChecker` and
  `alarmPermissionStatusProvider`.
- `AlarmPermissionBanner` on the Home: warns when notifications or exact
  alarms are disabled, with a shortcut to the app settings.
- Android manifest: `RECEIVE_BOOT_COMPLETED` and the
  `flutter_local_notifications` receivers, so alarms survive a reboot.
- ADR-012 (reliability and recovery).
- Tests: `OverdueClassifier`, `RecoveryService` (real Drift in memory, real
  `SchedulerEngine` and `TaskEngine`, fake notifier), permission status and
  the banner.

### Changed
- `GuiaGoApp` runs recovery on start (excluding the occurrence that opened
  the app) and on resume, and reloads Home/Dashboard/Calendar/Insights when
  occurrences were marked missed.
- Home shows the permission banner above the greeting.

### Fixed
- Alarm screen: "Adiar N min" now snoozes for the task's own snooze minutes
  (before, `AlarmRingController.snooze()` always used the 10-minute default).
