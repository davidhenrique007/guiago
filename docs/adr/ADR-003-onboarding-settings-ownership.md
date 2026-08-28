# ADR-003 — Settings lives under `features/onboarding`, not `features/settings`

## Status
Accepted (Fase 1)

## Context
Master spec §6 lists `onboarding` and `settings` as separate feature
folders. Onboarding is what *captures* `Settings` (profile, main
goal, day window, notification/TTS prefs, default snooze/tolerance);
a later Settings screen will *edit* the same data.

## Decision
For Fase 1, `Settings` (domain entity), `SettingsRepository`
(interface + Drift implementation), and the single `settings` Drift
table live under `features/onboarding/{domain,data}`, since
onboarding is the only feature that touches them so far.
`features/settings/` stays empty.

When the Settings screen is actually built, promote
`Settings`/`SettingsRepository` to a shared location (e.g.
`features/settings/domain`) and have onboarding depend on it instead
— a small, mechanical move, not a rewrite.

## Consequences
- No premature abstraction for a feature (`features/settings`) that
  doesn't exist yet.
- One migration step is deferred to whichever phase builds the real
  Settings screen — noted here so it isn't forgotten.
