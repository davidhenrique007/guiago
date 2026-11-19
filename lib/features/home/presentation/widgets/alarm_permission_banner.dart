import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../design_system/design_system.dart';
import '../../../scheduler/data/alarm_permission_providers.dart';
import '../../../scheduler/domain/alarm_permission_checker.dart';

/// Warns when the phone would silently drop GuiaGo's alarms
/// (notifications or exact alarms disabled) and offers a shortcut to
/// the app settings. Invisible when everything is granted. Re-checks
/// when the app returns to the foreground, so it disappears right after
/// the user fixes the permission.
class AlarmPermissionBanner extends ConsumerStatefulWidget {
  const AlarmPermissionBanner({super.key});

  @override
  ConsumerState<AlarmPermissionBanner> createState() =>
      _AlarmPermissionBannerState();
}

class _AlarmPermissionBannerState extends ConsumerState<AlarmPermissionBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(alarmPermissionStatusProvider);
    }
  }

  static String _message(AlarmPermissionStatus status) {
    if (!status.notificationsGranted && !status.exactAlarmsGranted) {
      return 'Activa as notificações e os alarmes exactos para os '
          'lembretes tocarem à hora.';
    }
    if (!status.notificationsGranted) {
      return 'Activa as notificações para os lembretes aparecerem.';
    }
    return 'Activa os alarmes exactos para os lembretes tocarem à hora certa.';
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AlarmPermissionStatus> statusAsync =
        ref.watch(alarmPermissionStatusProvider);
    final AlarmPermissionStatus? status = switch (statusAsync) {
      AsyncData<AlarmPermissionStatus>(:final value) => value,
      _ => null,
    };
    if (status == null || status.allGranted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Os alarmes podem não tocar',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_message(status), style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Abrir definições',
                    variant: AppButtonVariant.secondary,
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
