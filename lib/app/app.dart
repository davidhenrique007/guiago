import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/scheduler/data/scheduler_providers.dart';
import '../features/scheduler/domain/alarm_notifier.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// GuiaGo root widget. Wires theme + router on top of the Riverpod
/// [ProviderScope] created in `main.dart`, and listens for
/// notification taps so the alarm screen opens (Fase 4, ADR-008).
class GuiaGoApp extends ConsumerStatefulWidget {
  const GuiaGoApp({super.key});

  @override
  ConsumerState<GuiaGoApp> createState() => _GuiaGoAppState();
}

class _GuiaGoAppState extends ConsumerState<GuiaGoApp> {
  StreamSubscription<String>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    final AlarmNotifier notifications = ref.read(notificationServiceProvider);
    _tapSubscription = notifications.onNotificationTapped.listen(_openAlarm);
    unawaited(_checkLaunchPayload(notifications));
  }

  Future<void> _checkLaunchPayload(AlarmNotifier notifications) async {
    final String? payload = await notifications.checkLaunchPayload();
    if (payload != null) _openAlarm(payload);
  }

  void _openAlarm(String occurrenceId) {
    ref.read(appRouterProvider).go('/alarm/$occurrenceId');
  }

  @override
  void dispose() {
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
