import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Metadata table — schema version bookkeeping only.
///
/// This is the ONLY table created in Fase 0. Domain tables (`tasks`,
/// `task_occurrences`, `task_events`, `performance_records`, `scores`,
/// `levels`, `settings`, `alarm_records` — see master spec §15) are
/// intentionally deferred to the phases that own that domain
/// (Fase 2 Task Engine, Fase 5 Performance, etc.), so this file
/// doesn't get ahead of the phase that's actually allowed to run.
class AppMetadataTable extends Table {
  @override
  String get tableName => 'app_metadata';

  IntColumn get schemaVersion => integer()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {schemaVersion};
}

@DriftDatabase(tables: [AppMetadataTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For unit tests: pass an in-memory executor instead of opening a
  /// real file on disk.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
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
