import '../domain/alarm_permission_checker.dart';
import '../domain/alarm_permission_requester.dart';

/// Asks for alarm permissions at the moment they matter (the user just
/// created a task), and at most once per app run so a refusal is not
/// nagged again on every task. The Home banner keeps explaining what is
/// missing and offers the shortcut to the system settings.
class AlarmPermissionPrompter {
  AlarmPermissionPrompter({
    required AlarmPermissionChecker checker,
    required AlarmPermissionRequester requester,
  })  : _checker = checker,
        _requester = requester;

  final AlarmPermissionChecker _checker;
  final AlarmPermissionRequester _requester;
  bool _asked = false;

  /// Returns true when it actually showed the system prompts.
  Future<bool> promptIfNeeded() async {
    if (_asked) return false;
    try {
      final AlarmPermissionStatus status = await _checker.check();
      if (status.allGranted) return false;
      _asked = true;
      await _requester.request();
      return true;
    } on Object {
      return false;
    }
  }
}
