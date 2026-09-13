// TODO Implement this library.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tts_speaker.dart';
import '../infrastructure/tts_service.dart';

/// The TTS engine used to speak a task aloud when an alarm rings.
/// Typed as the [TtsSpeaker] interface (not `TtsService`) so tests
/// can override it with a fake that never touches platform channels
/// — same pattern as `notificationServiceProvider` in the scheduler
/// feature (see ADR-006/ADR-008).
final Provider<TtsSpeaker> ttsServiceProvider = Provider<TtsSpeaker>(
  (ref) => TtsService(),
);
