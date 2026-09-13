# ADR-008 — Notification tap opens the alarm screen; no full-screen intent yet

## Status
Accepted (Fase 4)

## Context
Master spec §24 describes the alarm experience but doesn't mandate a
specific delivery mechanism. There are two realistic ways to get the
user from "an alarm fired" to the `AlarmScreen`:

1. **Notification tap** — a normal local notification appears; the
   user taps it; the app opens (or comes to foreground) and
   navigates to `/alarm/:occurrenceId`. Requires no special Android
   permissions beyond what Fase 3 already requested.
2. **Full-screen intent** — the alarm screen appears automatically,
   even over the lock screen, without the user tapping anything
   (what a phone's built-in alarm clock does). Requires the
   `USE_FULL_SCREEN_INTENT` permission, additional manifest
   configuration, and different behavior per Android version (13+
   restricts it further).

## Decision
Fase 4 implements option 1 only. `NotificationService.scheduleAt()`
attaches the occurrence ID as the notification's `payload`;
`NotificationService.onNotificationTapped` (a stream) and
`checkLaunchPayload()` (for a cold start) both surface that payload;
`GuiaGoApp` listens for it and navigates to `AppRoutes.alarm`.

Full-screen intent is deliberately deferred. Reasons:
- It requires native manifest/permission changes beyond what's
  already documented in ADR from Fase 3, and Android 13+ requires
  the user to separately grant it in Settings — a whole permission
  flow of its own.
- The Task Creation UX and general notification behavior should be
  validated first with the simpler mechanism before adding the
  complexity (and battery/OS-vendor quirks) of full-screen intents.

## Consequences
- If the phone is locked when an alarm fires, the user sees a normal
  notification, not an automatic ringing screen — they must pull down
  the notification shade and tap it. This is a real UX gap relative
  to "GuiaGo behaves like an alarm clock" and should be revisited
  (likely in Fase 7, alongside boot recovery, or as its own follow-up
  phase) once the core experience is validated.
- Because tapping is required, `AlarmRingController` handles both
  "app already running, notification tapped" (`onNotificationTapped`
  stream) and "app cold-started by the tap" (`checkLaunchPayload()`)
  — both funnel into the same `_openAlarm` navigation in
  `GuiaGoApp`.