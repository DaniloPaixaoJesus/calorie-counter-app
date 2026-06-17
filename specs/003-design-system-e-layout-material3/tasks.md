# Tasks: Design System e Layout Material 3

**Input**: Documentos de design de `/specs/003-design-system-e-layout-material3/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Não há exigência explícita de TDD na spec; foco em implementação incremental com validação manual por história e gates finais de qualidade.

**Organization**: Tarefas agrupadas por história de usuário para permitir implementação e validação independentes.

## Phase 1: Setup (Infraestrutura Inicial)

**Purpose**: Preparar estrutura de arquivos e pontos de extensão para o novo Design System.

- [X] T001 Criar pasta de design system em `app/lib/design_system/`
- [X] T002 Criar arquivo de breakpoints em `app/lib/design_system/layout_breakpoints.dart`
- [X] T003 [P] Criar arquivo de catálogo de icon keys suportadas em `app/lib/design_system/icon_key_registry.dart`
- [X] T004 [P] Criar arquivo de mapeamento de icon key para `IconData` em `app/lib/utils/meal_icon_mapper.dart`

---

## Phase 2: Foundational (Pré-requisitos Bloqueantes)

**Purpose**: Consolidar tokens de tema e componentes base reutilizáveis antes das histórias.

**CRITICAL**: Nenhuma história deve começar antes desta fase.

- [X] T005 Atualizar tokens de cor, tipografia e esquema Material 3 em `app/lib/themes/nutrition_theme.dart`
- [X] T006 [P] Criar tokens de espaçamento em `app/lib/design_system/app_spacing.dart`
- [X] T007 [P] Criar tokens de raio e borda em `app/lib/design_system/app_radius.dart`
- [X] T008 [P] Criar tokens de elevação em `app/lib/design_system/app_elevation.dart`
- [X] T009 Criar componente base de cartão de ação em `app/lib/features/home/widgets/action_choice_card.dart`
- [X] T010 Criar componente base de seção/título para telas de fluxo em `app/lib/features/home/widgets/section_header.dart`

**Checkpoint**: Base visual e tokens prontos para implementação das histórias.

---

## Phase 3: User Story 1 - Home Material 3 com navegação inferior (Priority: P1) 🎯 MVP

**Goal**: Modernizar Home com card de calorias em destaque, lista limpa, estado vazio amigável e navegação inferior Home/Adicionar.

**Independent Test**: Usuário abre o app e consegue navegar entre Home/Adicionar com barra inferior, visualizar card de total e lista com layout consistente em tema claro.

### Implementation for User Story 1

- [X] T011 [P] [US1] Criar shell com navegação inferior (Home/Adicionar) em `app/lib/features/home/home_shell_page.dart`
- [X] T012 [US1] Atualizar bootstrap para abrir shell principal em `app/lib/main.dart`
- [X] T013 [P] [US1] Criar card de total de calorias reutilizável em `app/lib/features/home/widgets/calorie_total_card.dart`
- [X] T014 [P] [US1] Criar item de lista de refeição com layout padronizado em `app/lib/features/home/widgets/meal_list_item.dart`
- [X] T015 [US1] Refatorar tela Home para usar `CalorieTotalCard` e `MealListItem` em `app/lib/features/home/home_page.dart`
- [X] T016 [US1] Atualizar barra de navegação por data para novo visual em `app/lib/features/home/widgets/date_navigation_bar.dart`
- [X] T017 [US1] Atualizar estado vazio com mensagem amigável e tokens de tema em `app/lib/features/home/widgets/date_empty_state.dart`
- [X] T018 [US1] Atualizar diálogo de remoção para estilo Material 3 em `app/lib/features/home/widgets/meal_removal_dialog.dart`

**Checkpoint**: Home modernizada e navegável de forma independente.

---

## Phase 4: User Story 2 - Fluxo de adicionar refeição (texto/áudio) e revisão (Priority: P2)

**Goal**: Padronizar experiência visual do fluxo Adicionar, com seleção texto/áudio, gravação com timer e tela de revisão de estimativa.

**Independent Test**: Usuário entra na aba Adicionar, escolhe texto ou áudio, vê o fluxo de revisão com descrição/calorias/confiança/observação e conclui o salvamento.

### Implementation for User Story 2

- [X] T019 [P] [US2] Criar tela de escolha de entrada (texto/áudio) em `app/lib/features/home/add_meal_entry_page.dart`
- [X] T020 [US2] Integrar aba Adicionar da navegação inferior para abrir `AddMealEntryPage` em `app/lib/features/home/home_shell_page.dart`
- [X] T021 [P] [US2] Criar widget de indicador visual de gravação em `app/lib/features/home/widgets/audio_recording_indicator.dart`
- [X] T022 [US2] Atualizar fluxo de gravação com layout novo e timer em `app/lib/features/home/add_meal_page.dart`
- [X] T023 [P] [US2] Criar tela de revisão de estimativa em `app/lib/features/home/review_estimate_page.dart`
- [X] T024 [US2] Mover confirmação final para `ReviewEstimatePage` com retorno de dados em `app/lib/features/home/add_meal_page.dart`
- [X] T025 [US2] Atualizar formulário para estilo/tokens e legibilidade em `app/lib/features/home/widgets/meal_form.dart`
- [X] T026 [US2] Atualizar componente de aviso de confiança para nova linguagem visual em `app/lib/features/home/widgets/confidence_warning.dart`

**Checkpoint**: Fluxo Adicionar completo e consistente sem depender das demais histórias.

---

## Phase 5: User Story 3 - Retorno da IA com iconKey + fallback e persistência (Priority: P3)

**Goal**: Estender contrato de estimativa para incluir `iconKey`, `calorias` e `observacao`, persistindo `iconKey` em refeição e exibindo ícone correto na lista com fallback `default`.

**Independent Test**: Em entradas por texto e áudio, a estimativa retorna `iconKey`; refeição salva mantém chave válida; ícone inválido/ausente vira `default` e é exibido na Home.

### Implementation for User Story 3

- [X] T027 [P] [US3] Estender `AiEstimate` para `iconKey` e `observacao` em `app/lib/services/ai_adapter/ai_adapter.dart`
- [X] T028 [US3] Atualizar implementação mock para retornar `iconKey` considerando descrição e horário em `app/lib/services/ai_adapter/ai_adapter_mock.dart`
- [X] T029 [P] [US3] Estender modelo `Meal` com campo `iconKey` e validação de fallback em `app/lib/models/meal.dart`
- [X] T030 [US3] Atualizar `HomeViewModel` para normalizar `iconKey` e manter `observacao` da IA em `app/lib/features/home/view_model.dart`
- [X] T031 [US3] Atualizar confirmação de salvamento para persistir `iconKey` em `app/lib/features/home/add_meal_page.dart`
- [X] T032 [US3] Atualizar renderização da lista para usar ícone por `iconKey` em `app/lib/features/home/home_page.dart`
- [X] T033 [US3] Implementar fallback centralizado de icon key inválida/ausente em `app/lib/utils/meal_icon_mapper.dart`

**Checkpoint**: Regra de icon key da IA funcional para texto e áudio com fallback garantido.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Fechamentos finais de consistência, acessibilidade e qualidade.

- [X] T034 [P] Ajustar semântica e acessibilidade de botões/listas/diálogos em `app/lib/features/home/home_page.dart`
- [X] T035 [P] Ajustar semântica e acessibilidade no fluxo de adicionar em `app/lib/features/home/add_meal_page.dart`
- [X] T036 Atualizar guia de validação com evidências finais em `specs/003-design-system-e-layout-material3/quickstart.md`
- [X] T037 Executar formatação e ajustes de estilo em `app/lib/`
- [X] T038 Executar análise estática e corrigir alertas em `app/lib/`
- [X] T039 Executar suíte de testes existente e corrigir regressões em `app/test/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: inicia imediatamente.
- **Foundational (Phase 2)**: depende da Setup e bloqueia histórias.
- **User Stories (Phase 3-5)**: dependem de Foundational.
- **Polish (Phase 6)**: depende das histórias concluídas.

### User Story Dependencies

- **US1 (P1)**: inicia após Phase 2; entrega MVP visual da Home.
- **US2 (P2)**: inicia após Phase 2; pode evoluir em paralelo a US1 após `home_shell_page.dart` estar criado.
- **US3 (P3)**: inicia após Phase 2; depende de pontos de integração em `add_meal_page.dart` e `home_page.dart`.

### Within Each User Story

- Criar componentes/base antes da integração na tela.
- Integrar tela antes de refinamentos de acessibilidade.
- Validar critério independente da história antes de avançar.

### Parallel Opportunities

- Setup: `T003` e `T004` em paralelo.
- Foundational: `T006`, `T007`, `T008` em paralelo.
- US1: `T013` e `T014` em paralelo; `T016` e `T017` em paralelo após `T015`.
- US2: `T021` e `T023` em paralelo.
- US3: `T027` e `T029` em paralelo; `T032` e `T033` em paralelo após `T030`.
- Polish: `T034` e `T035` em paralelo.

---

## Parallel Example: User Story 1

```bash
# Componentes visuais em paralelo
T013 Criar card de total de calorias reutilizável em app/lib/features/home/widgets/calorie_total_card.dart
T014 Criar item de lista de refeição com layout padronizado em app/lib/features/home/widgets/meal_list_item.dart

# Refinos da Home em paralelo após integração base
T016 Atualizar barra de navegação por data para novo visual em app/lib/features/home/widgets/date_navigation_bar.dart
T017 Atualizar estado vazio com mensagem amigável e tokens de tema em app/lib/features/home/widgets/date_empty_state.dart
```

## Parallel Example: User Story 2

```bash
# Estruturas independentes do fluxo de adicionar
T021 Criar widget de indicador visual de gravação em app/lib/features/home/widgets/audio_recording_indicator.dart
T023 Criar tela de revisão de estimativa em app/lib/features/home/review_estimate_page.dart
```

## Parallel Example: User Story 3

```bash
# Contrato e modelo em paralelo
T027 Estender AiEstimate para iconKey e observacao em app/lib/services/ai_adapter/ai_adapter.dart
T029 Estender modelo Meal com campo iconKey e validação de fallback em app/lib/models/meal.dart
```

---

## Implementation Strategy

### MVP First (US1)

1. Concluir Setup e Foundational.
2. Entregar US1 completa.
3. Validar Home modernizada com navegação inferior e estado vazio.

### Incremental Delivery

1. US1 -> validação visual da Home.
2. US2 -> validação do fluxo Adicionar e revisão.
3. US3 -> validação da regra de `iconKey` da IA e fallback.
4. Polish -> acessibilidade + quality gates.

### Team Parallel Strategy

1. Base comum (Phase 1-2) em conjunto.
2. Distribuição por histórias:
   - Dev A: US1
   - Dev B: US2
   - Dev C: US3
3. Convergência final no Phase 6.

---

## Notes

- Tarefas com `[P]` não compartilham o mesmo arquivo no mesmo momento.
- Cada história é independente e validável por critério próprio.
- Implementação deve manter simplicidade, offline-first e aderência à constitution.
