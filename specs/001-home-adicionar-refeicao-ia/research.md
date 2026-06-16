# Research: Home + Adicionar Refeição (IA)

**Created**: 2026-06-15
**Purpose**: Resolver esclarecimentos técnicos e registrar decisões para o plano de implementação.

## Questions / Unknowns

- Q1: Transcrição de áudio — on‑device (`speech_to_text`) vs serviços externos (Google Speech, Whisper API).
- Q2: Segurança de chaves se chamada direta a APIs de IA for necessária (sem backend permitido).
- Q3: Prompt design para estimativa calórica e formato de resposta (campos esperados).
- Q4: UX para baixa confiança e revisão manual.

## Findings & Decisions

1. **Transcrição de áudio com abstração**
   - Opção 1: Acoplar diretamente a `speech_to_text` (simples mas inflexível).
   - Opção 2: Criar `AudioTranscriptionAdapter` como interface, permitir múltiplas implementações (offline, API de IA).
   - **Decisão**: Opção 2. Implementar `OfflineAudioTranscriptionAdapter` via `speech_to_text` no MVP; dejar `AiApiAudioTranscriptionAdapter` como stub para futura integração (Whisper API, Google Cloud Speech).
   - **Rationale**: Desacopla UI da implementação. Alinhado com Constituição (Arquitetura preparada para evolução, Offline First). Mesma abordagem que `AiAdapter`.
   
2. **Interface de transcrição**
   - `AudioTranscriptionAdapter` expõe:
     - `startListening()` → inicia captura
     - `stopListening()` → encerra captura
     - `Stream<TranscriptionEvent>` → emite `TranscriptionResult` ou `TranscriptionError`
     - `isListening` → estado booleano
     - `statusMessage` → descrição em língua natural
   - Emite resultados continuamente (`isFinal: false` durante fala, `isFinal: true` ao fim).
   - Suporta threshold de confiança (0.7 é limite para aviso de revisão).

2. IA / Estimativa calórica
   - Definir `AiAdapter` com método `estimateCalories(text) -> {description, calories, note, confidence}`.
   - No MVP usar `ai_adapter_mock` que aplica regras simples (mapeamento de alimentos comuns → estimativas heurísticas) e retorna confiança alta para entradas simples.

3. Segurança e privacidade
   - Evitar armazenar chaves secretas no app. Se for necessária integração real, preferir proxy/backend gerenciado (fora do MVP) ou mecanismo de token rotativo.
   - Como consta na Constituição, o app PODE usar internet apenas para IA/LLM; isso requer documentação de privacidade no `plan.md` e consentimento do usuário.

4. UX de revisão
   - Mostrar: transcrição (se áudio), descrição interpretada pela IA, calorias estimadas, observação curta e indicador de confiança.
   - Se confidence < 0.6 (exemplo), exibir aviso e destacar campos editáveis com sugestão de correção.

## Alternatives Considered

- Chamar LLM diretamente do app: prático mas arriscado (expor chaves). Rejeitado para MVP.
- Forçar apenas entrada por texto: reduz acessibilidade; rejeitado.

## Action Items

- Implementar `AiAdapter` interface e `ai_adapter_mock`.
- Documentar permissões de microfone e fluxos de fallback em `quickstart.md`.
- Criar `contracts/ai_adapter.md` descrevendo payloads e timeouts.

