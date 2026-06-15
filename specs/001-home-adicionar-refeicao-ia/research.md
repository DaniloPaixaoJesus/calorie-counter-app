# Research: Home + Adicionar Refeição (IA)

**Created**: 2026-06-15
**Purpose**: Resolver esclarecimentos técnicos e registrar decisões para o plano de implementação.

## Questions / Unknowns

- Q1: Transcrição de áudio — on‑device (`speech_to_text`) vs serviços externos (Google Speech, Whisper API).
- Q2: Segurança de chaves se chamada direta a APIs de IA for necessária (sem backend permitido).
- Q3: Prompt design para estimativa calórica e formato de resposta (campos esperados).
- Q4: UX para baixa confiança e revisão manual.

## Findings & Decisions

1. Transcrição
   - Opções: `speech_to_text` (on‑device) permite sem conexão; Whisper/Cloud oferecem melhor acurácia mas requerem internet.
   - Decisão: usar `speech_to_text` em MVP quando disponível; aceitar transcrição via adaptador (mock) para testes automatizados. Documentar como alternativa se equipe optar por chamar API externa.

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

