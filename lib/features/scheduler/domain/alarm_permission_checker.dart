/// Whether the phone will actually let GuiaGo's alarms ring.
class AlarmPermissionStatus {
  const AlarmPermissionStatus({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;

  bool get allGranted => notificationsGranted && exactAlarmsGranted;
}

/// Read-only permission check. Kept apart from `AlarmNotifier` on
/// purpose: adding a method there would break every existing fake.
abstract interface class AlarmPermissionChecker {
  Future<AlarmPermissionStatus> check();
}
