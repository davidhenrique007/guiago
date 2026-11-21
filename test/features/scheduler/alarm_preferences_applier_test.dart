import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/scheduler/application/alarm_preferences_applier.dart';
import 'package:guiago/features/scheduler/domain/alarm_notifier.dart';

class _FakeNotifier implements AlarmNotifier {
  int cancelAllCalls = 0;

  @override
  Future<Result<void>> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> cancel(int id) async => const Success<void>(null);

  @override
  Future<Result<void>> cancelAll() async {
    cancelAllCalls++;
    return const Success<void>(null);
  }

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<String?> checkLaunchPayload() async => null;
}

void main() {
  test('notifications on: re-arms the live alarms, cancels nothing', () async {
    final _FakeNotifier notifier = _FakeNotifier();
    int rearmed = 0;
    final AlarmPreferencesApplier applier = AlarmPreferencesApplier(
      notifier: notifier,
      rearm: () async => rearmed++,
    );

    await applier.apply(notificationsEnabled: true);

    expect(rearmed, 1);
    expect(notifier.cancelAllCalls, 0);
  });

  test('notifications off: cancels the alarms, re-arms none', () async {
    final _FakeNotifier notifier = _FakeNotifier();
    int rearmed = 0;
    final AlarmPreferencesApplier applier = AlarmPreferencesApplier(
      notifier: notifier,
      rearm: () async => rearmed++,
    );

    await applier.apply(notificationsEnabled: false);

    expect(notifier.cancelAllCalls, 1);
    expect(rearmed, 0);
  });

  test('a failure while re-arming never escapes', () async {
    final AlarmPreferencesApplier applier = AlarmPreferencesApplier(
      notifier: _FakeNotifier(),
      rearm: () async => throw StateError('boom'),
    );

    await expectLater(applier.apply(notificationsEnabled: true), completes);
  });
}
