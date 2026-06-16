---
description: "Tarefas de implementação da feature 001 — Home e adicionar refeição com IA"
feature_dir: specs/001-home-adicionar-refeicao-ia
app_dir: app
---

# Tarefas: Home e adicionar refeição com estimativa calórica por IA

**Feature**: `001-home-adicionar-refeicao-ia` | **Plano**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

> Todo código de aplicação fica em `app/`. Comandos de qualidade: `cd app && dart format . && flutter analyze && flutter test`.

---

## Fase 1: Setup (Estrutura do Projeto)

- [X] T001 Atualizar `app/pubspec.yaml` adicionando dependências: `speech_to_text`, `uuid` e `provider` (ou `flutter` built-in `ChangeNotifier`) com versões compatíveis com Flutter 3.x
- [X] T002 Criar tema e tokens: `app/lib/themes/nutrition_theme.dart` com `ColorScheme.fromSeed(seedColor: Color(0xFF2E7D32))` e tokens `secondary`, `background`, `success`, `warning`
- [X] T003 [P] Criar estrutura de pastas em `app/lib/`: `features/home/`, `features/home/widgets/`, `services/ai_adapter/`, `services/speech/`, `services/repository/`, `models/`, `themes/`
- [X] T004 [P] Criar pastas `app/test/unit/` e `app/test/widget/` e garantir que `app/test/widget_test.dart` gerado pelo `flutter create` compila sem erros

## Fase 2: Fundacionais (pré-requisitos bloqueantes)

- [X] T005 Criar modelo `app/lib/models/meal.dart` com campos `id` (uuid), `descricao`, `calorias` (int), `timestamp`, `origem` (enum `texto`|`audio`), `aiConfidence` (double?), `nota` (String?); incluir construtor `const`, `copyWith` e validações
- [X] T006 [P] Definir interface `AiAdapter` em `app/lib/services/ai_adapter/ai_adapter.dart` conforme contrato em `specs/001-home-adicionar-refeicao-ia/contracts/ai_adapter.md` (`estimateCalories(String) → Future<AiEstimate>`, classes `AiEstimate` e `AiAdapterException`)
- [X] T007 [P] Implementar `app/lib/services/ai_adapter/ai_adapter_mock.dart`: mapear palavras-chave comuns → estimativas fixas; `confidence: 0.9` para reconhecidos, `0.5` para desconhecidos, `0.3`+`calorias: 0` quando sem palavras-chave; delay simulado de 300ms
- [X] T008 [P] Definir interface `AudioTranscriptionAdapter` em `app/lib/services/audio_transcription/audio_transcription_adapter.dart` conforme contrato em `specs/001-home-adicionar-refeicao-ia/contracts/audio_transcription_adapter.md` (métodos `startListening()`, `stopListening()`, propriedade `transcriptionStream: Stream<TranscriptionEvent>`, tipos `TranscriptionResult`, `TranscriptionError`)
- [X] T008a [P] Implementar `app/lib/services/audio_transcription/offline_audio_transcription_adapter.dart`: encapsular `speech_to_text`, emitir `TranscriptionResult` continuamente enquanto usuário fala, `isFinal: true` ao fim, estimar `confidence` de resultado, tratar erros via `TranscriptionError`
- [X] T008b [P] Criar stub `app/lib/services/audio_transcription/aiapi_audio_transcription_adapter.dart`: implementar interface `AudioTranscriptionAdapter`, lançar `NotImplementedError` em `startListening()` com mensagem "API de IA não implementada neste MVP"; serve como placeholder para futuras integrações
- [X] T009 [P] Implementar `app/lib/services/repository/in_memory_repository.dart` com operações `add(Meal)`, `getAll()`, `remove(String id)` e total diário `getTotalCaloriesHoje()`
- [X] T010 Implementar `app/lib/features/home/view_model.dart` (`ChangeNotifier`) integrando `InMemoryRepository` e `AiAdapter`; expor `meals`, `totalHoje`, `isLoading`, `estimate`, `lowConfidence` (threshold `< 0.7`), `errorMessage`

**Checkpoint**: executar `flutter analyze` em `app/` sem erros antes de iniciar histórias de usuário.

---

## Fase 3: US1 — Registrar refeição por texto (P1) 🎯 MVP

**Objetivo**: Digitar descrição → solicitar estimativa IA → revisar/editar → salvar → ver lista e total.

**Teste independente**: Home (vazio) → "Adicionar refeição" → digitar texto → botão estimar → revisar → confirmar → lista atualizada + total correto.

- [X] T011 [US1] Criar `app/lib/features/home/widgets/meal_form.dart`: campos `TextField` para `descricao` (multilinha) e `calorias` (numérico), ambos editáveis; emitir callback `onChanged`
- [X] T012 [US1] Criar `app/lib/features/home/add_meal_page.dart`: modo texto com `MealForm`, botão "Estimar com IA" que chama `viewModel`, exibir `CircularProgressIndicator` enquanto `isLoading`; botões "Confirmar" e "Cancelar"
- [X] T013 [US1] Conectar confirmação em `add_meal_page.dart` ao `viewModel.addMeal(meal)` e navegar de volta à Home após sucesso
- [X] T014 [US1] Criar `app/lib/features/home/home_page.dart`: `AppBar` com título "Calorie Counter", card de total diário no topo (`FR-001`), `ListView` de refeições com nome e calorias (`FR-002`), estado vazio com mensagem, `FloatingActionButton` para adicionar (`FR-003`, `FR-004`)
- [X] T015 [US1] Integrar `HomeViewModel` via `ChangeNotifierProvider` em `app/lib/main.dart`; configurar roteamento `MaterialApp` entre `HomePage` e `AddMealPage`
- [X] T016 [US1] Adicionar `app/test/widget/us1_text_flow_test.dart`: testar (1) Home exibe estado vazio, (2) adicionar refeição por texto preenche lista, (3) total é recalculado; usar `AiAdapterMock`

---

## Fase 4: US2 — Registrar refeição por áudio (P1)

**Objetivo**: Gravar áudio on-device → transcrever → estimar calorias → revisar → salvar.

**Teste independente**: botão microfone → gravação → parar → transcrição em `MealForm` → estimar → confirmar → lista atualizada.

- [ ] T017 [US2] Adicionar permissão de microfone em `app/android/app/src/main/AndroidManifest.xml` (`RECORD_AUDIO`) e em `app/ios/Runner/Info.plist` (`NSMicrophoneUsageDescription`)
- [ ] T018 [US2] Integrar `AudioTranscriptionAdapter` (implementação `OfflineAudioTranscriptionAdapter`) em `app/lib/features/home/add_meal_page.dart`: botão de microfone (ícone gravando/parado), chamar `startListening()`, escutar `transcriptionStream`, preencher `MealForm.descricao` ao receber `TranscriptionResult.text`, parar com `stopListening()`
- [ ] T019 [US2] Implementar tratamento de erros de transcrição em `add_meal_page.dart`: capturar `TranscriptionError` no stream, exibir `SnackBar` ou `AlertDialog` com mensagem específica (permissão negada, sem áudio, timeout, etc.); guiar usuário para habilitar microfone se necessário (`FR-006`)
- [ ] T020 [US2] Adicionar `app/test/widget/us2_audio_flow_test.dart`: testar fluxo com `OfflineAudioTranscriptionAdapter` mockado retornando `TranscriptionResult` com `isFinal: false` e depois `isFinal: true`; validar preenchimento do formulário e sequência estimativa → confirmação

---

## Fase 5: US3 — Revisar e editar sugestão da IA (P2)

**Objetivo**: Exibir sugestão da IA em campos editáveis, avisar quando `confidence < 0.7`, permitir salvar após revisão.

**Teste independente**: sugestão de baixa confiança → aviso visível → editar calorias → confirmar → lista com valor editado.

- [X] T021 [US3] Criar `app/lib/features/home/widgets/confidence_warning.dart`: widget condicional que exibe banner/card de aviso quando `confidence < 0.7`, destacando campos editáveis (`FR-011`)
- [X] T022 [US3] Criar `app/lib/features/home/widgets/review_suggestion_dialog.dart`: exibir `descricaoInterpretada`, `calorias`, `nota` e `confidence`; campos `descricao` e `calorias` editáveis; botões "Salvar" e "Cancelar"
- [X] T023 [US3] Integrar `ConfidenceWarning` e `ReviewSuggestionDialog` em `add_meal_page.dart`: abrir diálogo após estimativa retornar; exibir aviso quando `viewModel.lowConfidence == true`
- [X] T024 [US3] Garantir que `calorias == 0` force edição manual antes de habilitar "Salvar" (desabilitar botão enquanto `calorias <= 0`)
- [X] T025 [US3] Adicionar `app/test/unit/us3_viewmodel_test.dart`: testar (1) `lowConfidence` true quando `confidence < 0.7`, (2) edição de calorias atualiza estado, (3) `calorias == 0` impede confirmação sem edição

---

## Fase 6: Polish & Qualidade

- [X] T026 [P] Executar `cd app && dart format . && flutter analyze` e resolver todos os warnings/hints; garantir zero erros de análise
- [ ] T027 Validar contrastes de acessibilidade em `app/lib/themes/nutrition_theme.dart` (mínimo AA 4.5:1 para texto normal); ajustar cores se necessário e adicionar variante de alto contraste
- [ ] T028 Garantir tratamento de edge cases: entrada ambígua (`confidence < 0.3` → forçar edição), áudio inaudível (`onError` no `SpeechService` → mensagem de erro), texto > 1000 chars → truncar visualmente na lista
- [ ] T029 Executar suite completa `flutter test` em `app/` e garantir todos os testes passando; adicionar cobertura mínima dos fluxos US1/US2/US3

---

## Dependências & Ordem de Execução

```
Fase 1 (Setup) → Fase 2 (Fundacionais) → Fase 3 (US1) → Fase 4 (US2) + Fase 5 (US3) → Fase 6 (Polish)
```

- Dentro de cada fase: modelos/interfaces → serviços/mocks → view model → UI → testes
- US2 e US3 podem ser desenvolvidas em paralelo após US1 estar completa

## Oportunidades de Paralelismo

- `T003`, `T004`, `T006`, `T007`, `T008`, `T008a`, `T008b`, `T009` — paralelas (infraestrutura independente)
- `T017`, `T018`, `T019` (US2) + `T021`, `T022`, `T023` (US3) — paralelas entre si após Fase 2

## Escopo do MVP (Sugestão)

Fase 1 + Fase 2 + **Fase 3 (US1)** = app utilizável e validável de forma independente.

---


