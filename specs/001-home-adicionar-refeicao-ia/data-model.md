# Data Model: Meal (Refeição) e Camada de Transcrição de Áudio

## Entity: Meal

- `id`: string (uuid)
- `descricao`: string — descrição completa informada/interpretada
- `calorias`: integer — valor estimado/ajustado pelo usuário
- `timestamp`: ISO-8601 datetime
- `origem`: enum(`texto`, `audio`)
- `ai_confidence`: number (0..1) opcional
- `nota`: string opcional (observação curta da IA)

## Validation Rules

- `descricao` DEVE ser não vazia.
- `calorias` DEVE ser inteiro não-negativo.
- `timestamp` DEVE refletir a data/hora do registro; na ausência de especificação, usar o horário atual.

## Example JSON

```json
{
  "id": "uuid-1234",
  "descricao": "arroz, feijão, frango grelhado e salada",
  "calorias": 650,
  "timestamp": "2026-06-15T12:34:00Z",
  "origem": "texto",
  "ai_confidence": 0.92,
  "nota": "Estimativa baseada em porções médias"
}
```

---

## Camada de Transcrição de Áudio

### Tipos: AudioTranscriptionAdapter

A interface `AudioTranscriptionAdapter` define o contrato para transcrição de áudio:

```dart
abstract class AudioTranscriptionAdapter {
  Future<void> startListening();
  Future<void> stopListening();
  Stream<TranscriptionEvent> get transcriptionStream;
  bool get isListening;
  String get statusMessage;
}

abstract class TranscriptionEvent {}

class TranscriptionResult extends TranscriptionEvent {
  final String text;        // áudio transcrito
  final bool isFinal;       // true quando reconhecimento completo
  final double confidence;  // 0.0 a 1.0
}

class TranscriptionError extends TranscriptionEvent {
  final String code;        // ex: 'permission_denied', 'no_match', 'timeout'
  final String message;
}
```

### Validações de Transcrição

- `text` DEVE ser não vazio quando `isFinal: true`.
- `confidence` DEVE estar no intervalo [0.0, 1.0].
- `confidence >= 0.7` → resultado confiável.
- `confidence < 0.7` → avisar usuário para revisar.
- `confidence <= 0.3` → sugerir repetição.

### Implementações

1. **OfflineAudioTranscriptionAdapter** (MVP)
   - Usa `speech_to_text` plugin Flutter (reconhecimento nativo do SO).
   - Offline, sem dependência de internet.
   - Latência baixa, resultado em tempo real.
   - Disponível em Android e iOS.

2. **AiApiAudioTranscriptionAdapter** (Futura, stub)
   - Placeholder para integração com Whisper API, Google Cloud Speech, etc.
   - Não será implementada no MVP.
   - Mesma interface `AudioTranscriptionAdapter`.

### Relações

```
Meal.origem = "audio" 
  ↓
User presse botão microfone
  ↓
OfflineAudioTranscriptionAdapter.startListening()
  ↓
Stream emite TranscriptionResult com texto
  ↓
UI preenche Meal.descricao com transcrito
  ↓
Prossegue fluxo normal: estimar calorias → revisar → salvar
```

