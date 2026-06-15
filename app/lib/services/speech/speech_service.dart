import 'package:speech_to_text/speech_to_text.dart';

/// Encapsula o pacote speech_to_text para transcrição on-device.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _initialized;
  }

  /// Inicia escuta. [onResult] é chamado com o texto transcrito.
  Future<void> startListening({required void Function(String) onResult}) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'pt_BR',
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }
}
