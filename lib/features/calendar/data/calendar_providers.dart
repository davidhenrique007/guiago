import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../tasks/data/task_providers.dart';
import '../application/calendar_controller.dart';
import '../application/calendar_service.dart';
import '../domain/calendar_task_detail.dart';

final Provider<CalendarService> calendarServiceProvider =
    Provider<CalendarService>((ref) {
  return CalendarService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

/// Detail of one occurrence for the read-only sheet. Auto-disposed:
/// it is only alive while the sheet is open, so it is always fresh.
final calendarTaskDetailProvider =
    FutureProvider.autoDispose.family<CalendarTaskDetail, String>((
  ref,
  String occurrenceId,
) async {
  final result =
      await ref.read(calendarServiceProvider).loadDetail(occurrenceId);
  return switch (result) {
    Success<CalendarTaskDetail>(:final value) => value,
    Fail<CalendarTaskDetail>(:final failure) => throw CalendarLoadException(
        failure,
      ),
  };
});
