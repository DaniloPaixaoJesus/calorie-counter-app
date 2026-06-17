import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'audio_transcription_adapter.dart';

/// Implementação MVP que usa `speech_to_text` para transcrição on-device.
class OfflineAudioTranscriptionAdapter implements AudioTranscriptionAdapter {
  final SpeechToText _speech = SpeechToText();
  final _controller = StreamController<TranscriptionEvent>.broadcast();
  bool _initialized = false;

  @override
  bool get isListening => _speech.isListening;

  @override
  String get statusMessage => _initialized ? 'initialized' : 'not initialized';

  @override
  Stream<TranscriptionEvent> get transcriptionStream => _controller.stream;

  @override
  Future<void> dispose() async {
    _controller.close();
    _speech.cancel();
  }

  @override
  Future<void> initialize(
      {void Function(String error)? onError,
      void Function(String status)? onStatus}) async {
    if (_initialized) return;
    try {
      _initialized = await _speech.initialize(
        onError: (e) => onError?.call(e.errorMsg),
        onStatus: (s) => onStatus?.call(s),
      );
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  @override
  Future<void> startListening(
      {required void Function(String text, bool isFinal) onResult,
      void Function(String status)? onStatus,
      Duration maxDuration = const Duration(seconds: 30)}) async {
    if (!_initialized) await initialize();
    if (!_initialized) {
      _controller.add(const TranscriptionError(
          code: 'not_initialized', message: 'Speech not initialized'));
      return;
    }

    await _speech.listen(
      onResult: (result) {
        final texto = result.recognizedWords.trim();
        if (texto.isNotEmpty) {
          // `speech_to_text` nem sempre expõe confiança; usar 0.0 como fallback.
          final confidence = 0.0;
          final ev = TranscriptionResult(
              text: texto, isFinal: result.finalResult, confidence: confidence);
          _controller.add(ev);
          onResult(ev.text, ev.isFinal);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'pt_BR',
        partialResults: false,
        listenFor: maxDuration,
        pauseFor: maxDuration,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      _controller
          .add(TranscriptionError(code: 'stop_error', message: e.toString()));
    }
  }
}
