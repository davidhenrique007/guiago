import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Metadata table — schema version bookkeeping only.
class AppMetadataTable extends Table {
  @override
  String get tableName => 'app_metadata';

  IntColumn get schemaVersion => integer()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {schemaVersion};
}

/// User profile + preferences captured during onboarding (Fase 1).
/// Single-row table — always keyed by `id = 0`.
@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get mainObjective => text().withDefault(const Constant(''))();
  IntColumn get dayStartMinutes =>
      integer().withDefault(const Constant(7 * 60))();
  IntColumn get dayEndMinutes =>
      integer().withDefault(const Constant(22 * 60))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get ttsEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get defaultSnoozeMinutes =>
      integer().withDefault(const Constant(10))();
  IntColumn get defaultToleranceMinutes =>
      integer().withDefault(const Constant(15))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A task's persisted row (Fase 2, master spec §10, §15).
@DataClassName('TaskRow')
class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text()();

  /// One of: none, daily, weekly, customDays.
  TextColumn get recurrenceType => text()();

  /// Comma-separated `DateTime.weekday` ints (1=Mon..7=Sun).
  /// Only meaningful when [recurrenceType] is `customDays`.
  TextColumn get recurrenceWeekdays => text().nullable()();

  IntColumn get defaultToleranceMinutes => integer()();
  IntColumn get defaultSnoozeMinutes => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single scheduled instance of a task (Fase 2, master spec §10).
@DataClassName('TaskOccurrenceRow')
@TableIndex(name: 'idx_occurrences_task_id', columns: {#taskId})
class TaskOccurrencesTable extends Table {
  @override
  String get tableName => 'task_occurrences';

  TextColumn get id => text()();
  TextColumn get taskId => text().references(TasksTable, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get triggeredAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// One of: scheduled, triggered, snoozed, completed, declined,
  /// missed, cancelled.
  TextColumn get status => text()();

  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  IntColumn get responseTimeSeconds => integer().nullable()();
  IntColumn get toleranceMinutes => integer()();
  TextColumn get declineReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// An append-only occurrence status-transition log entry (Fase 2,
/// master spec §10 — "the system must preserve history").
@DataClassName('TaskEventRow')
@TableIndex(name: 'idx_events_occurrence_id', columns: {#occurrenceId})
class TaskEventsTable extends Table {
  @override
  String get tableName => 'task_events';

  TextColumn get id => text()();
  TextColumn get taskId => text().references(TasksTable, #id)();
  TextColumn get occurrenceId => text().references(TaskOccurrencesTable, #id)();
  TextColumn get fromStatus => text()();
  TextColumn get toStatus => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Links a [TaskOccurrence] to the native alarm scheduled for it
/// (Fase 3, master spec §13). Keyed by `occurrenceId` — an occurrence
/// has at most one live alarm record at a time.
@DataClassName('AlarmRecordRow')
class AlarmRecordsTable extends Table {
  @override
  String get tableName => 'alarm_records';

  TextColumn get occurrenceId => text().references(TaskOccurrencesTable, #id)();
  TextColumn get taskId => text().references(TasksTable, #id)();
  IntColumn get nativeAlarmId => integer()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {occurrenceId};
}

/// Agregado de desempenho para uma janela de tempo (Fase 5,
/// master spec §15, §18). Múltiplas linhas — uma por período
/// calculado (dia/semana/mês).
@DataClassName('PerformanceRecordRow')
@TableIndex(
  name: 'idx_performance_records_period',
  columns: {#periodStart},
)
class PerformanceRecordsTable extends Table {
  @override
  String get tableName => 'performance_records';

  TextColumn get id => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();

  IntColumn get totalOccurrences => integer()();
  IntColumn get completedCount => integer()();
  IntColumn get completedAfterSnoozeCount => integer()();
  IntColumn get missedCount => integer()();
  IntColumn get declinedCount => integer()();
  IntColumn get snoozedCount => integer()();

  RealColumn get completionRate => real()();
  RealColumn get missRate => real()();
  RealColumn get snoozeRate => real()();

  /// Em segundos — mesma convenção do responseTimeSeconds em
  /// TaskOccurrencesTable. Null quando não há resposta registada.
  IntColumn get averageResponseTimeSeconds => integer().nullable()();

  DateTimeColumn get calculatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ledger auditável de pontuação (Fase 5, master spec §19) —
/// append-only, nunca editado. O agregado fica em ScoresTable.
@DataClassName('ScoreEntryRow')
@TableIndex(
  name: 'idx_score_entries_occurrence_id',
  columns: {#occurrenceId},
)
class ScoreEntriesTable extends Table {
  @override
  String get tableName => 'score_entries';

  TextColumn get id => text()();
  TextColumn get occurrenceId => text().references(TaskOccurrencesTable, #id)();

  /// One of: completed, completedAfterSnooze, missed, declined.
  TextColumn get reason => text()();
  IntColumn get points => integer()();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Score agregado — single-row, sempre `id = 0` (mesmo padrão do
/// SettingsTable: app single-user local).
@DataClassName('ScoreRow')
class ScoresTable extends Table {
  @override
  String get tableName => 'scores';

  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Histórico de avaliações de nível (Fase 5, master spec §15, §20).
/// Múltiplas linhas — cada avaliação do LevelEngine gera uma.
@DataClassName('LevelRow')
class LevelsTable extends Table {
  @override
  String get tableName => 'levels';

  TextColumn get id => text()();

  /// One of: beginner, consistent, disciplined, elite.
  TextColumn get tier => text()();
  TextColumn get previousTier => text()();

  IntColumn get scoreAtEvaluation => integer()();
  DateTimeColumn get evaluatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Streak agregado — single-row, sempre `id = 0` (mesmo padrão
/// do ScoresTable).
@DataClassName('StreakStatusRow')
class StreakStatusTable extends Table {
  @override
  String get tableName => 'streak_status';

  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastFulfilledDate => dateTime().nullable()();
  DateTimeColumn get calculatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AppMetadataTable,
    SettingsTable,
    TasksTable,
    TaskOccurrencesTable,
    TaskEventsTable,
    AlarmRecordsTable,
    PerformanceRecordsTable,
    ScoreEntriesTable,
    ScoresTable,
    LevelsTable,
    StreakStatusTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For unit tests: pass an in-memory executor instead of opening a
  /// real file on disk.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(settingsTable);
          }
          if (from < 3) {
            await m.createTable(tasksTable);
            await m.createTable(taskOccurrencesTable);
            await m.createTable(taskEventsTable);
          }
          if (from < 4) {
            await m.createTable(alarmRecordsTable);
          }
          if (from < 5) {
            await m.createTable(performanceRecordsTable);
            await m.createTable(scoreEntriesTable);
            await m.createTable(scoresTable);
            await m.createTable(levelsTable);
            await m.createTable(streakStatusTable);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'guiago.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
