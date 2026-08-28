import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Timezone-aware scheduling helper (master spec §14 — ADR-004).
///
/// GuiaGo task times are a **local wall-clock concept**: "20:00"
/// means 8pm wherever the device currently is, not a fixed UTC
/// instant. [toLocalTZDateTime] anchors a plain [DateTime] (as
/// produced by [DateTime.now] / task scheduling) to the device's
/// actual IANA location so `flutter_local_notifications` fires it at
/// the intended local moment.
///
/// ADR-004 decision: if the device's timezone changes (travel) after
/// an alarm is scheduled, the alarm keeps the local time-of-day it
/// was created with, re-anchored to the new zone — this is why
/// `SchedulerEngine.rescheduleAll` exists, so recovery (Fase 7) can
/// re-run this conversion against the current zone.
///
/// NOTE: requires the `flutter_timezone` package to read the
/// device's IANA name — add it with `flutter pub add
/// flutter_timezone` (deliberately not hand-pinned to a version
/// here; let pub resolve one compatible with this project's SDK
/// constraint).
abstract final class TimezoneService {
  static bool _initialized = false;

  /// Loads the tz database and sets [tz.local] to the device's real
  /// IANA timezone. Idempotent — cheap to call from every entry
  /// point that needs it.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    String locationName;
    try {
      locationName = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      // Offline-first fallback (master spec §2/§25): scheduling must
      // never hard-fail just because the platform channel is
      // unavailable. UTC is always a valid, if imprecise, fallback.
      locationName = 'UTC';
    }

    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _initialized = true;
  }

  /// Converts a local wall-clock [dateTime] into a [tz.TZDateTime]
  /// anchored to [tz.local]. Call [ensureInitialized] first.
  static tz.TZDateTime toLocalTZDateTime(DateTime dateTime) {
    assert(
      _initialized,
      'TimezoneService.ensureInitialized() must run before converting',
    );
    return tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  /// Test-only hook to force re-initialization between test cases.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
  }
}
