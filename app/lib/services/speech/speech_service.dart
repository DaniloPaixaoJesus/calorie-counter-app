import 'package:speech_to_text/speech_to_text.dart';

/// Encapsula o pacote speech_to_text para transcrição on-device.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  }) async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) => onError?.call(error.errorMsg),
      onStatus: (status) => onStatus?.call(status),
    );
    return _initialized;
  }

  /// Inicia escuta. [onResult] é chamado com o texto transcrito.
  /// [onStatus] notifica mudanças de estado (ex: 'notListening', 'done').
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    await _speech.listen(
      onResult: (result) {
        final texto = result.recognizedWords.trim();
        if (texto.isNotEmpty) {
          onResult(texto, result.finalResult);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'pt_BR',
        partialResults: true,
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
