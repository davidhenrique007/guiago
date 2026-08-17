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
