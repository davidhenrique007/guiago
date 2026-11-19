import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/result/result.dart';
import '../features/calendar/application/calendar_controller.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/home/application/home_controller.dart';
import '../features/insights/application/insights_controller.dart';
import '../features/recovery/data/recovery_providers.dart';
import '../features/recovery/domain/recovery_report.dart';
import '../features/scheduler/data/scheduler_providers.dart';
import '../features/scheduler/domain/alarm_notifier.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// GuiaGo root widget. Wires theme + router on top of the Riverpod
/// [ProviderScope] created in `main.dart`, listens for notification
/// taps so the alarm screen opens (Fase 4, ADR-008), and runs the
/// recovery pass when the app starts and when it returns to the
/// foreground (Fase 7, ADR-012).
class GuiaGoApp extends ConsumerStatefulWidget {
  const GuiaGoApp({super.key});

  @override
  ConsumerState<GuiaGoApp> createState() => _GuiaGoAppState();
}

class _GuiaGoAppState extends ConsumerState<GuiaGoApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AlarmNotifier notifications = ref.read(notificationServiceProvider);
    _tapSubscription = notifications.onNotificationTapped.listen(_openAlarm);
    unawaited(_start(notifications));
  }

  /// Cold start: open the alarm if a notification launched the app,
  /// then reconcile alarms. The alarm being opened is excluded from
  /// recovery so the two never race.
  Future<void> _start(AlarmNotifier notifications) async {
    final String? payload = await notifications.checkLaunchPayload();
    if (!mounted) return;
    if (payload != null) _openAlarm(payload);
    await _runRecovery(excludeOccurrenceId: payload);
  }

  void _openAlarm(String occurrenceId) {
    ref.read(appRouterProvider).go('/alarm/$occurrenceId');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runRecovery());
    }
  }

  /// Best-effort by design: a recovery problem must never crash the app.
  Future<void> _runRecovery({String? excludeOccurrenceId}) async {
    if (!mounted) return;
    try {
      final Result<RecoveryReport> result = await ref
          .read(recoveryServiceProvider)
          .run(excludeOccurrenceId: excludeOccurrenceId);
      if (!mounted) return;
      final RecoveryReport? report = result.valueOrNull;
      if (report != null && report.changedOccurrences) {
        _refreshScreens();
      }
    } catch (error) {
      debugPrint('Recovery failed: $error');
    }
  }

  /// Recovery resolved occurrences as missed: every screen that shows
  /// occurrence data must reload.
  void _refreshScreens() {
    ref.invalidate(homeControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(calendarControllerProvider);
    ref.invalidate(insightsControllerProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'GuiaGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
