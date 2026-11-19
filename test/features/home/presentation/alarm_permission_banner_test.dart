import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/home/presentation/widgets/alarm_permission_banner.dart';
import 'package:guiago/features/scheduler/data/alarm_permission_providers.dart';
import 'package:guiago/features/scheduler/domain/alarm_permission_checker.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester,
    AlarmPermissionStatus status,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmPermissionStatusProvider.overrideWith((ref) async => status),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AlarmPermissionBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows nothing when every permission is granted', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      const AlarmPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: true,
      ),
    );

    expect(find.text('Os alarmes podem não tocar'), findsNothing);
  });

  testWidgets('asks for notifications when only they are missing', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      const AlarmPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: true,
      ),
    );

    expect(find.text('Os alarmes podem não tocar'), findsOneWidget);
    expect(
      find.text('Activa as notificações para os lembretes aparecerem.'),
      findsOneWidget,
    );
    expect(find.text('Abrir definições'), findsOneWidget);
  });

  testWidgets('asks for exact alarms when only they are missing', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      const AlarmPermissionStatus(
        notificationsGranted: true,
        exactAlarmsGranted: false,
      ),
    );

    expect(
      find.text(
        'Activa os alarmes exactos para os lembretes tocarem à hora certa.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('asks for both when both are missing', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      const AlarmPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      ),
    );

    expect(
      find.text(
        'Activa as notificações e os alarmes exactos para os lembretes '
        'tocarem à hora.',
      ),
      findsOneWidget,
    );
  });
}
