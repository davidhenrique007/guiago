import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/task_providers.dart';
import '../application/calendar_service.dart';

final Provider<CalendarService> calendarServiceProvider =
    Provider<CalendarService>((ref) {
  return CalendarService(
    occurrenceRepository: ref.watch(taskOccurrenceRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});
