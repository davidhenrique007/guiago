import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/alarm_permission_prompter.dart';
import '../domain/alarm_permission_checker.dart';
import '../domain/alarm_permission_requester.dart';
import '../infrastructure/permission_handler_alarm_permission_checker.dart';
import '../infrastructure/permission_handler_alarm_permission_requester.dart';

final Provider<AlarmPermissionChecker> alarmPermissionCheckerProvider =
    Provider<AlarmPermissionChecker>(
  (ref) => const PermissionHandlerAlarmPermissionChecker(),
);

/// Current permission state. `autoDispose` so it is re-read every time
/// a screen that shows it is opened.
final alarmPermissionStatusProvider =
    FutureProvider.autoDispose<AlarmPermissionStatus>((ref) {
  final AlarmPermissionChecker checker =
      ref.watch(alarmPermissionCheckerProvider);
  return checker.check();
});

final Provider<AlarmPermissionRequester> alarmPermissionRequesterProvider =
    Provider<AlarmPermissionRequester>(
  (ref) => const PermissionHandlerAlarmPermissionRequester(),
);

/// One instance per app run: remembers that the user was already asked.
final Provider<AlarmPermissionPrompter> alarmPermissionPrompterProvider =
    Provider<AlarmPermissionPrompter>(
  (ref) => AlarmPermissionPrompter(
    checker: ref.watch(alarmPermissionCheckerProvider),
    requester: ref.watch(alarmPermissionRequesterProvider),
  ),
);
