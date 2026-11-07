import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voce: usa il riconoscimento vocale e la sintesi vocale già presenti nel
/// telefono. Gratis, senza AI esterne.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final SpeechToText _stt = SpeechToText();
  FlutterTts? _tts;
  bool _sttReady = false;

  void Function(String error)? _onError;
  void Function(String status)? _onStatus;

  Future<bool> ensureListening() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(
        onError: (e) => _onError?.call(e.errorMsg),
        onStatus: (s) => _onStatus?.call(s),
      );
    } catch (e) {
      debugPrint('Trovo: voce non disponibile ($e)');
      _sttReady = false;
    }
    return _sttReady;
  }

  bool get isListening => _stt.isListening;

  /// Ascolta e chiama [onWords] mentre capisce le parole.
  Future<bool> listen({
    required String localeTag,
    required void Function(String words, bool isFinal) onWords,
    void Function(double level)? onLevel,
    void Function(String error)? onError,
    void Function()? onDone,
  }) async {
    if (!await ensureListening()) return false;
    _onError = onError;
    _onStatus = (s) {
      if (s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) {
        onDone?.call();
      }
    };
    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) =>
            onWords(r.recognizedWords, r.finalResult),
        onSoundLevelChange: onLevel == null
            ? null
            : (level) => onLevel(((level + 2) / 12).clamp(0.0, 1.0)),
        listenOptions: SpeechListenOptions(
          localeId: localeTag.replaceAll('-', '_'),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Trovo: errore ascolto ($e)');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }

  Future<void> speak(String text, {required String localeTag}) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.stop();
      await tts.setLanguage(localeTag);
      // Un po' più lenta del normale: più facile da capire.
      await tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
      await tts.setPitch(1.0);
      await tts.speak(text);
    } catch (e) {
      debugPrint('Trovo: sintesi vocale non disponibile ($e)');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
