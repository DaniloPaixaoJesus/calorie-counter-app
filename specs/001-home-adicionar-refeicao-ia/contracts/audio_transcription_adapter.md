# Contrato: AudioTranscriptionAdapter

**Feature**: 001-home-adicionar-refeicao-ia  
**Criado**: 2026-06-16  
**Status**: Definido

## Visão Geral

`AudioTranscriptionAdapter` é a interface que desacopla a transcrição de áudio de qualquer implementação específica. No MVP, a implementação é `OfflineAudioTranscriptionAdapter` via `speech_to_text`. A interface DEVE ser substituível sem alteração nos widgets ou na lógica de apresentação.

Esta abstração segue o mesmo padrão de `AiAdapter` para permitir:
1. Transcrição offline no dispositivo
2. Transcrição via API de IA (OpenAI Whisper, Google Cloud Speech, etc.)
3. Outras soluções futuras

A UI nunca deve conhecer diretamente qual implementação está ativa.

## Interface Dart

```dart
// app/lib/services/audio_transcription/audio_transcription_adapter.dart

abstract class AudioTranscriptionAdapter {
  /// Inicia a escuta de áudio do microfone.
  ///
  /// Emite eventos de transcrição através do stream [transcriptionStream].
  /// Lança [AudioTranscriptionException] se permissões não forem concedidas
  /// ou se o dispositivo não possuir microfone disponível.
  Future<void> startListening();

  /// Para a escuta de áudio.
  ///
  /// Não lança exceção; operação idempotente.
  Future<void> stopListening();

  /// Stream de eventos de transcrição em tempo real.
  ///
  /// Emite [TranscriptionResult] a cada atualização reconhecida.
  /// Emite erro via [TranscriptionError] se falha irrecuperável ocorrer.
  /// Stream encerra quando [stopListening()] é chamado.
  Stream<TranscriptionEvent> get transcriptionStream;

  /// Indica se o adaptador está atualmente escutando.
  bool get isListening;

  /// Obtém uma descrição do estado atual.
  String get statusMessage;
}

/// Evento de transcrição emitido pelo stream.
abstract class TranscriptionEvent {
  const TranscriptionEvent();
}

/// Transcrição bem-sucedida.
class TranscriptionResult extends TranscriptionEvent {
  final String text;
  final bool isFinal; // true quando reconhecimento está completo
  final double confidence; // 0.0 a 1.0

  const TranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
  });
}

/// Erro durante transcrição.
class TranscriptionError extends TranscriptionEvent {
  final String code; // ex: 'permission_denied', 'no_match', 'timeout'
  final String message;

  const TranscriptionError({
    required this.code,
    required this.message,
  });
}

class AudioTranscriptionException implements Exception {
  final String message;
  const AudioTranscriptionException(this.message);
}
```

## Entrada

Não há entrada direta. O adaptador recebe áudio capturado do microfone do dispositivo durante `startListening()`.

## Saída (`TranscriptionResult`)

| Campo         | Tipo      | Obrigatório | Regras                                           |
|---------------|-----------|-------------|--------------------------------------------------|
| `text`        | `String`  | Sim         | Não vazio; contém áudio transcrito               |
| `isFinal`     | `bool`    | Sim         | true quando reconhecimento foi finalizado        |
| `confidence`  | `double`  | Sim         | 0.0 a 1.0 inclusive                              |

## Erros

| Condição                              | Comportamento esperado                                      |
|---------------------------------------|-------------------------------------------------------------|
| Permissão de microfone negada         | Lançar `AudioTranscriptionException('permission_denied')`   |
| Dispositivo sem microfone             | Lançar `AudioTranscriptionException('no_microphone')`       |
| Sem áudio reconhecível                | Emitir `TranscriptionError('no_match', 'Nenhum áudio')`     |
| Timeout (timeout default 15 segundos) | Emitir `TranscriptionError('timeout', 'Tempo limite')`      |
| Erro do serviço subjacente            | Emitir `TranscriptionError('service_error', description)`   |

## Threshold de Confiança

- `confidence >= 0.7` → considerar transcrição confiável
- `confidence < 0.7` → exibir indicador de confiança baixa para o usuário revisar
- `confidence <= 0.3` → considerar não confiável; sugerir repetição

## Implementações

### OfflineAudioTranscriptionAdapter (MVP)

Localização: `app/lib/services/audio_transcription/offline_audio_transcription_adapter.dart`

Tecnologia: `speech_to_text` (plugin Flutter que usa Speech Recognition nativo do SO)

Características:
- Sem dependência de internet
- Latência baixa (resultado em tempo real durante fala)
- Precisão varia conforme idioma/sotaque e qualidade do áudio
- Funciona offline no dispositivo

Fluxo:
1. `startListening()` ativa microfone e inicia reconhecimento contínuo
2. Cada atualização de reconhecimento emite `TranscriptionResult` com `isFinal: false`
3. Quando usuário para de falar, emite `TranscriptionResult` com `isFinal: true`
4. `stopListening()` encerra streaming e libera microfone

### AiApiAudioTranscriptionAdapter (Futuro, não implementado no MVP)

Localização: `app/lib/services/audio_transcription/aiapi_audio_transcription_adapter.dart` (stub)

Tecnologia: OpenAI Whisper API, Google Cloud Speech, ou similar

Características:
- Requer conexão com internet
- Maior precisão em sotaques variados
- Suporta múltiplos idiomas nativamente
- Custo operacional por requisição

Será implementada no futuro mantendo a mesma interface `AudioTranscriptionAdapter`.

## Localização no Monorepo

```
app/lib/services/audio_transcription/
├── audio_transcription_adapter.dart        # interface + tipos
├── offline_audio_transcription_adapter.dart # implementação MVP
└── aiapi_audio_transcription_adapter.dart  # stub (futura)
```

Além disso, o diretório `app/lib/services/speech/` pode ser deprecado ou mantido como compatibilidade se necessário.

## Exemplo de Uso

```dart
final AudioTranscriptionAdapter transcriber = OfflineAudioTranscriptionAdapter();

// Iniciar escuta
try {
  await transcriber.startListening();
} catch (e) {
  print('Erro ao iniciar microfone: $e');
}

// Processar eventos
transcriber.transcriptionStream.listen((event) {
  if (event is TranscriptionResult) {
    print('Transcrição: ${event.text} (confiança: ${event.confidence})');
    if (event.isFinal) {
      print('Transcrição finalizada');
      transcriber.stopListening();
    }
  } else if (event is TranscriptionError) {
    print('Erro: ${event.code} - ${event.message}');
  }
});
```

## Decisões Arquiteturais

### AD-001: Por que abstração em interfaces?

**Decisão**: Definir `AudioTranscriptionAdapter` como interface (abstract class).

**Rationale**:
- Desacopla a UI da implementação específica (offline vs API).
- Permite trocar estratégia sem alterar widgets ou view models.
- Facilita testes com mocks determinísticos.
- Segue o padrão estabelecido em `AiAdapter`.

### AD-002: Stream vs callbacks

**Decisão**: Usar Dart `Stream<TranscriptionEvent>` para emitir resultados continuamente.

**Rationale**:
- Necessário capturar múltiplas atualizações enquanto usuário fala.
- Permite feedback em tempo real na UI.
- Padrão idiomatic em Dart/Flutter.

### AD-003: Offline-first no MVP

**Decisão**: MVP usa `OfflineAudioTranscriptionAdapter` via `speech_to_text`.

**Rationale**:
- Alinhado com Constituição (Offline First).
- Não requer chaves de API ou gerenciamento de tokens.
- Zero latência; resultado em tempo real.
- Integração simples com Android/iOS nativos.

## Evolução Futura

Quando equipe decidir integrar Whisper ou Google Cloud Speech:

1. Criar `AiApiAudioTranscriptionAdapter` implementando `AudioTranscriptionAdapter`.
2. Adicionar novo tipo `TranscriptionEventWithLanguageDetection` se necessário.
3. Atualizar `HomeViewModel` para permitir seleção de adaptador via configuração.
4. Nenhuma mudança em widgets ou lógica de negócio.

</content>
</invoke>