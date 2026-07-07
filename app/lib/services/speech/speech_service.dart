import 'dart:ui';

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
  ///
  /// A escuta não para automaticamente por silêncio: só termina quando o
  /// usuário solicita ([stopListening]) ou ao atingir [maxDuration].
  /// Os resultados parciais ficam desabilitados, portanto o texto só é
  /// entregue ao final da gravação.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
    Duration maxDuration = const Duration(seconds: 30),
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
        localeId: _speechLocale(),
        partialResults: false,
        // Mantém a escuta ativa durante silêncios; só para ao atingir o limite.
        listenFor: maxDuration,
        pauseFor: maxDuration,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }

  String _speechLocale() {
    final locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'pt') return 'pt_BR';
    if (locale.languageCode == 'es') return 'es_ES';
    return 'en_US';
  }
}
