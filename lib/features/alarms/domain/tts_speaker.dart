import '../../../core/result/result.dart';

/// The speech operations [AlarmRingController] needs. Implemented by
/// `TtsService` (Infrastructure) for the real app; fakeable in tests
/// without touching platform channels.
abstract interface class TtsSpeaker {
  Future<Result<void>> speak(String text);
  Future<Result<void>> stop();
}
