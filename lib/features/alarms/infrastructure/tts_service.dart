import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/tts_speaker.dart';

/// Thin wrapper around `flutter_tts` — reads the task aloud when an
/// alarm rings (master spec §4/§24: TTS is part of the alarm
/// experience). The only file that imports `flutter_tts`.
class TtsService implements TtsSpeaker {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<Result<void>> speak(String text) async {
    try {
      await _tts.setLanguage('pt-PT');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(PlatformFailure('Failed to speak', cause: e));
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _tts.stop();
      return const Success<void>(null);
    } catch (e) {
      return Fail<void>(PlatformFailure('Failed to stop speech', cause: e));
    }
  }
}
