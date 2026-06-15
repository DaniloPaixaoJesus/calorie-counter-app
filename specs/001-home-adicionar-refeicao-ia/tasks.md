description: "Tarefas geradas para implementação da feature"
---


# Tarefas: Home e adicionar refeição com estimativa calórica por IA

**Input**: Documentos em [specs/001-home-adicionar-refeicao-ia](specs/001-home-adicionar-refeicao-ia)

## Fase 0: Ambiente e Ferramentas (pré-requisito)

- [ ] T001 Instalar Flutter local (ou garantir `flutter` no PATH) e verificar com `flutter --version`
- [ ] T002 Instalar Android SDK platform-tools (`adb`) e expor `ANDROID_SDK_ROOT`/`PATH` (ver `docs/setup.md`)
- [ ] T003 Instalar `cmdline-tools` (sdkmanager, avdmanager) e `emulator` no Android SDK
- [ ] T004 Validar ambiente com `flutter doctor -v` e adicionar evidências em `specs/001-home-adicionar-refeicao-ia/docs/environment-proof.md`

## Fase 1: Setup (Estrutura do Projeto)

- [ ] T005 Criar esqueleto do app Flutter: `lib/main.dart`, `pubspec.yaml`, `analysis_options.yaml`
- [ ] T006 Criar tema e tokens: `lib/themes/nutrition_theme.dart` (Material 3 ColorScheme)
- [ ] T007 [P] Criar pastas de teste `test/unit/` e `test/widget/` e adicionar configuração básica de testes

## Fase 2: Fundacionais (pré-requisitos bloqueantes)

- [ ] T008 Criar modelo `lib/models/meal.dart` com campos: `id`, `descricao`, `calorias`, `timestamp`, `origem`, `ai_confidence`, `nota`
- [ ] T009 [P] Definir interface `AiAdapter` em `lib/services/ai_adapter/ai_adapter.dart`
- [ ] T010 [P] Implementar mock `AiAdapter` em `lib/services/ai_adapter/ai_adapter_mock.dart` (para testes/MVP)
- [ ] T011 [P] Criar abstração de transcrição `lib/services/speech/speech_service.dart` (hooks para transcrição on-device)
- [ ] T012 [P] Implementar repositório em memória `lib/services/repository/in_memory_repository.dart` com operações CRUD para `Meal`
- [ ] T013 Implementar `lib/features/home/view_model.dart` (ChangeNotifier) integrando modelo, repositório e `AiAdapter`

**Checkpoint**: Completar Fundacionais antes de iniciar as histórias de usuário.

## Fase 3: História de Usuário 1 - Registrar refeição por texto (Prioridade: P1) 🎯 MVP

Objetivo: Adicionar refeição via texto, pedir estimativa IA, revisar e salvar localmente.

Teste independente: Abrir Home → Adicionar refeição → digitar texto → solicitar estimativa → revisar → confirmar → verificar lista e total.

- [ ] T014 [US1] Implementar formulário `lib/features/home/widgets/meal_form.dart` (campos: descricao, calorias editáveis)
- [ ] T015 [US1] Implementar página de adicionar `lib/features/home/add_meal_page.dart` com entrada de texto e botão enviar
- [ ] T016 [US1] Implementar lógica de solicitação de estimativa via `AiAdapter` e preencher campos de revisão em `lib/features/home/view_model.dart`
- [ ] T017 [US1] Implementar listagem `lib/features/home/home_page.dart` e cálculo de total diário
- [ ] T018 [US1] Adicionar teste de widget `test/widget/us1_add_meal_test.dart` cobrindo fluxo de texto (incluir mocks do `AiAdapter`)

## Fase 4: História de Usuário 2 - Registrar refeição por áudio (Prioridade: P1)

Objetivo: Gravar áudio on-device, transcrever localmente, pedir estimativa IA e salvar após revisão.

Teste independente: Gravar → transcrever → solicitar estimativa → revisar → confirmar.

- [ ] T019 [US2] Integrar `lib/services/speech/speech_service.dart` em `lib/features/home/add_meal_page.dart` (gravar/parar)
- [ ] T020 [US2] Implementar fluxo de transcrição on-device e preencher `meal_form` a partir da transcrição em `lib/features/home/view_model.dart`
- [ ] T021 [US2] Adicionar tratamento de permissões e instruções de uso em `lib/features/home/add_meal_page.dart` (microfone)
- [ ] T022 [US2] Adicionar teste de widget `test/widget/us2_audio_flow_test.dart` validando fluxo de áudio com transcrição mockada

## Fase 5: História de Usuário 3 - Revisar e editar sugestão da IA (Prioridade: P2)

Objetivo: Permitir revisão/edição da sugestão, exibir aviso de baixa confiança e permitir salvar mesmo assim.

Teste independente: Receber sugestão → editar campos → salvar → verificar lista.

- [ ] T023 [US3] Implementar diálogo de revisão `lib/features/home/widgets/review_suggestion_dialog.dart` (edição de descricao e calorias)
- [ ] T024 [US3] Implementar componente/aviso `lib/features/home/widgets/confidence_warning.dart` e lógica de threshold em `lib/features/home/view_model.dart`
- [ ] T025 [US3] Implementar fluxo que permite salvar apesar de baixa confiança (com aviso) em `lib/features/home/view_model.dart`
- [ ] T026 [US3] Adicionar testes unitários `test/unit/us3_review_tests.dart` cobrindo edição e baixa confiança

## Fase N: Polish & Questões Transversais

- [ ] T027 [P] Atualizar `specs/001-home-adicionar-refeicao-ia/quickstart.md` com passos de validação
- [ ] T028 Limpeza de código, aplicar `dart format` e resolver `analysis` warnings
- [ ] T029 Adicionar verificações de acessibilidade/contraste e variante de alto contraste em `lib/themes/nutrition_theme.dart`
- [ ] T030 Documentar considerações de privacidade e chaves de IA em `specs/001-home-adicionar-refeicao-ia/research.md`

## Dependências & Ordem de Execução

- Setup (Fase 1) → Fundacionais (Fase 2) → Histórias de usuário (Fase 3+) → Polish
- Dentro de cada história: modelos → serviços → viewmodels → UI → testes

## Oportunidades de paralelismo

- T007, T009, T010, T011 e T012 podem ser implementadas em paralelo (tarefas de infra e mocks)
- Depois de Fundacionais, US1, US2 e US3 podem ser trabalhadas em paralelo por membros diferentes da equipe

## Estratégia de implementação

- MVP: completar Fase 1 + Fase 2, entregar US1 como primeiro incremento (validar independentemente)
- Em seguida, adicionar US2 (áudio) e US3 (revisão) e finalizar Polish

---


