import 'dart:async';

/// Eventos emitidos pela camada de transcrição de áudio.
abstract class TranscriptionEvent {
  const TranscriptionEvent();
}

class TranscriptionResult extends TranscriptionEvent {
  final String text;
  final bool isFinal;
  final double confidence;

  const TranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
  });
}

class TranscriptionError extends TranscriptionEvent {
  final String code;
  final String message;

  const TranscriptionError({required this.code, required this.message});
}

class AudioTranscriptionException implements Exception {
  final String message;
  const AudioTranscriptionException(this.message);
}

/// Interface abstrata para adaptadores de transcrição de áudio.
abstract class AudioTranscriptionAdapter {
  Future<void> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  });

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
    Duration maxDuration = const Duration(seconds: 30),
  });

  Future<void> stopListening();

  Stream<TranscriptionEvent> get transcriptionStream;

  bool get isListening;

  String get statusMessage;

  void dispose();
}
