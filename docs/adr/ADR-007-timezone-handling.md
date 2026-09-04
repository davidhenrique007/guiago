# ADR-007 — Timezone handling: device IANA zone, never bare UTC

## Status
Accepted (Fase 3)

## Context
Master spec §14 is explicit: "Horários de tarefas são conceitos de
horário local. Nunca tratar horário local como simples UTC sem
considerar timezone" — and requires documenting the decision in an
ADR.

## Decision
- All task/occurrence times (`Task`, `TaskOccurrence.scheduledAt`,
  etc.) are stored and manipulated as plain Dart `DateTime` values
  representing **local wall-clock time** — never normalized to UTC
  anywhere in the Domain or Data layers.
- Only at the single point where a `DateTime` crosses into the native
  alarm API (`NotificationService.scheduleAt`) does it get converted
  to a `tz.TZDateTime`, built from the device's actual IANA timezone
  name (fetched via the `flutter_timezone` plugin,
  `FlutterTimezone.getLocalTimezone()`) rather than assumed or
  hardcoded.
- `NotificationService.initialize()` calls
  `tz_data.initializeTimeZones()` and `tz.setLocalLocation(...)`
  once, before the first scheduling call — every subsequent
  `tz.TZDateTime.from(dateTime, tz.local)` conversion then reflects
  the device's real zone.
- `RecurrenceEngine` (Fase 2) deliberately operates on plain
  `DateTime` and never touches `tz.TZDateTime` — recurrence math
  (next daily/weekly/customDays occurrence) is a local wall-clock
  concept independent of the alarm layer, consistent with keeping
  Domain free of Infrastructure concerns.

## Consequences (and open follow-ups)
- If the device's timezone changes (travel, manual change) while
  alarms are already scheduled, those alarms were scheduled against
  the *previous* `tz.local` — they still fire at the same UTC instant
  they were originally computed for, not at the "same local time" in
  the new zone. Master spec §14 leaves the exact policy for this case
  to be defined; for now, `SchedulerEngine.rescheduleAll()` (already
  built in this phase) is the repair mechanism — Fase 7 will decide
  when to call it automatically (e.g. on a detected timezone change,
  alongside boot recovery).
- System clock changes are handled the same way: `rescheduleAll()` is
  the general-purpose "make native alarms match the database again"
  operation Fase 7 will hook into app resume / boot.