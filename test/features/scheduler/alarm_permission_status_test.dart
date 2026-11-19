import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/scheduler/domain/alarm_permission_checker.dart';

void main() {
  group('AlarmPermissionStatus.allGranted', () {
    test('is true only when notifications and exact alarms are granted', () {
      expect(
        const AlarmPermissionStatus(
          notificationsGranted: true,
          exactAlarmsGranted: true,
        ).allGranted,
        isTrue,
      );
      expect(
        const AlarmPermissionStatus(
          notificationsGranted: false,
          exactAlarmsGranted: true,
        ).allGranted,
        isFalse,
      );
      expect(
        const AlarmPermissionStatus(
          notificationsGranted: true,
          exactAlarmsGranted: false,
        ).allGranted,
        isFalse,
      );
    });
  });
}
