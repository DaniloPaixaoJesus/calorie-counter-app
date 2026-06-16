import 'dart:async';

import 'audio_transcription_adapter.dart';

/// Stub para futura implementação de transcrição via API de IA.
class AiApiAudioTranscriptionAdapter implements AudioTranscriptionAdapter {
  final _controller = StreamController<TranscriptionEvent>.broadcast();
  bool _initialized = false;

  @override
  bool get isListening => false;

  @override
  String get statusMessage => _initialized ? 'initialized' : 'not initialized';

  @override
  Stream<TranscriptionEvent> get transcriptionStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> initialize({void Function(String error)? onError, void Function(String status)? onStatus}) async {
    _initialized = true;
  }

  @override
  Future<void> startListening({required void Function(String text, bool isFinal) onResult, void Function(String status)? onStatus, Duration maxDuration = const Duration(seconds: 30)}) async {
    throw UnimplementedError('API de IA não implementada no MVP');
  }

  @override
  Future<void> stopListening() async {
    // noop
  }
}
