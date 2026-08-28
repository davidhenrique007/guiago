import '../../../core/result/result.dart';
import 'settings.dart';

/// Domain-facing contract for reading/writing [Settings]. The Data
/// layer provides the real (Drift-backed) implementation — Domain
/// and Application code depend only on this interface.
abstract interface class SettingsRepository {
  /// Returns the stored [Settings], or [Settings.initial] if none
  /// have been saved yet.
  Future<Result<Settings>> getSettings();

  /// Persists [settings], replacing whatever was stored before.
  Future<Result<void>> saveSettings(Settings settings);
}
