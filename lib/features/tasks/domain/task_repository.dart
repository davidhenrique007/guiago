import '../../../core/result/result.dart';
import 'task.dart';

/// Domain-facing contract for reading/writing [Task]s. Implemented
/// by `DriftTaskRepository` in the Data layer.
abstract interface class TaskRepository {
  Future<Result<Task>> saveTask(Task task);

  Future<Result<Task?>> getTask(String id);

  /// Non-archived tasks, most recently updated first.
  Future<Result<List<Task>>> getActiveTasks();

  Future<Result<void>> archiveTask(String id);

  Future<Result<void>> deleteTask(String id);
}
