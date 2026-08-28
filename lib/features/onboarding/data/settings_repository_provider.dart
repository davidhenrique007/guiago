import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../domain/settings_repository.dart';
import 'drift_settings_repository.dart';

/// Application/Presentation code depends on [SettingsRepository]
/// (the interface); this provider is the only place that knows the
/// concrete implementation is Drift-backed.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return DriftSettingsRepository(db);
});
