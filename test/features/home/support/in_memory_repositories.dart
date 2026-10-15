import 'package:guiago/core/result/result.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/onboarding/domain/settings_repository.dart';
import 'package:guiago/features/tasks/domain/task.dart';
import 'package:guiago/features/tasks/domain/task_repository.dart';

/// In-memory fakes for the Home feature's tests. Pairs with
/// InMemoryTaskOccurrenceRepository in
/// test/features/performance/support/in_memory_repositories.dart —
/// import both where a test needs tasks AND occurrences.
class InMemoryTaskRepository implements TaskRepository {
  final List<Task> items = <Task>[];

  @override
  Future<Result<Task>> saveTask(Task task) async {
    items
      ..removeWhere((t) => t.id == task.id)
      ..add(task);
    return Success<Task>(task);
  }

  @override
  Future<Result<Task?>> getTask(String id) async {
    for (final Task task in items) {
      if (task.id == id) return Success<Task?>(task);
    }
    return const Success<Task?>(null);
  }

  @override
  Future<Result<List<Task>>> getActiveTasks() async {
    return Success<List<Task>>(
      items.where((task) => !task.isArchived).toList(),
    );
  }

  @override
  Future<Result<void>> archiveTask(String id) async {
    final int index = items.indexWhere((task) => task.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isArchived: true);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    items.removeWhere((task) => task.id == id);
    return const Success<void>(null);
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  Settings settings = Settings.initial;

  @override
  Future<Result<Settings>> getSettings() async => Success<Settings>(settings);

  @override
  Future<Result<void>> saveSettings(Settings value) async {
    settings = value;
    return const Success<void>(null);
  }
}
