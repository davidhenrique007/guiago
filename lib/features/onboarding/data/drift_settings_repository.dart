import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../../core/services/app_database.dart';
import '../domain/settings.dart';
import '../domain/settings_repository.dart';

/// The single row we ever read/write in `settings`.
const int _kSettingsRowId = 0;

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<Settings>> getSettings() async {
    try {
      final SettingsRow? row = await (_db.select(_db.settingsTable)
            ..where((SettingsTable t) => t.id.equals(_kSettingsRowId)))
          .getSingleOrNull();

      if (row == null) return const Success<Settings>(Settings.initial);
      return Success<Settings>(_toDomain(row));
    } catch (e) {
      return Fail<Settings>(
        DatabaseFailure('Failed to load settings', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    try {
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              id: const Value<int>(_kSettingsRowId),
              userName: Value<String>(settings.userName),
              mainObjective: Value<String>(settings.mainObjective),
              dayStartMinutes: Value<int>(settings.dayStartMinutes),
              dayEndMinutes: Value<int>(settings.dayEndMinutes),
              notificationsEnabled: Value<bool>(settings.notificationsEnabled),
              ttsEnabled: Value<bool>(settings.ttsEnabled),
              defaultSnoozeMinutes: Value<int>(settings.defaultSnoozeMinutes),
              defaultToleranceMinutes:
                  Value<int>(settings.defaultToleranceMinutes),
              onboardingCompleted: Value<bool>(settings.onboardingCompleted),
            ),
          );
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(
        DatabaseFailure('Failed to save settings', cause: e),
      );
    }
  }

  Settings _toDomain(SettingsRow row) => Settings(
        userName: row.userName,
        mainObjective: row.mainObjective,
        dayStartMinutes: row.dayStartMinutes,
        dayEndMinutes: row.dayEndMinutes,
        notificationsEnabled: row.notificationsEnabled,
        ttsEnabled: row.ttsEnabled,
        defaultSnoozeMinutes: row.defaultSnoozeMinutes,
        defaultToleranceMinutes: row.defaultToleranceMinutes,
        onboardingCompleted: row.onboardingCompleted,
      );
}
