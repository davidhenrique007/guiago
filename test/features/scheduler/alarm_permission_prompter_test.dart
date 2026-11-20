import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/scheduler/application/alarm_permission_prompter.dart';
import 'package:guiago/features/scheduler/domain/alarm_permission_checker.dart';
import 'package:guiago/features/scheduler/domain/alarm_permission_requester.dart';

const AlarmPermissionStatus _granted = AlarmPermissionStatus(
  notificationsGranted: true,
  exactAlarmsGranted: true,
);
const AlarmPermissionStatus _denied = AlarmPermissionStatus(
  notificationsGranted: false,
  exactAlarmsGranted: false,
);

class _FakeChecker implements AlarmPermissionChecker {
  _FakeChecker(this.status, {this.throws = false});

  final AlarmPermissionStatus status;
  final bool throws;

  @override
  Future<AlarmPermissionStatus> check() async {
    if (throws) throw StateError('boom');
    return status;
  }
}

class _FakeRequester implements AlarmPermissionRequester {
  int calls = 0;

  @override
  Future<AlarmPermissionStatus> request() async {
    calls++;
    return _denied;
  }
}

void main() {
  test('does not ask when everything is already granted', () async {
    final _FakeRequester requester = _FakeRequester();
    final AlarmPermissionPrompter prompter = AlarmPermissionPrompter(
      checker: _FakeChecker(_granted),
      requester: requester,
    );

    expect(await prompter.promptIfNeeded(), isFalse);
    expect(requester.calls, 0);
  });

  test('asks when something is missing, but only once per run', () async {
    final _FakeRequester requester = _FakeRequester();
    final AlarmPermissionPrompter prompter = AlarmPermissionPrompter(
      checker: _FakeChecker(_denied),
      requester: requester,
    );

    expect(await prompter.promptIfNeeded(), isTrue);
    expect(await prompter.promptIfNeeded(), isFalse);
    expect(requester.calls, 1);
  });

  test('a failing check never throws and never asks', () async {
    final _FakeRequester requester = _FakeRequester();
    final AlarmPermissionPrompter prompter = AlarmPermissionPrompter(
      checker: _FakeChecker(_denied, throws: true),
      requester: requester,
    );

    expect(await prompter.promptIfNeeded(), isFalse);
    expect(requester.calls, 0);
  });
}
