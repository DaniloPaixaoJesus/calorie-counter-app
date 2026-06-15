tests/
# Implementation Plan: Home e adicionar refeição com estimativa calórica por IA

**Branch**: `001-home-adicionar-refeicao-ia` | **Date**: 2026-06-15 | **Spec**: ../spec.md

**Input**: Feature specification from `/specs/001-home-adicionar-refeicao-ia/spec.md`

## Summary

Permitir que o usuário registre refeições por texto ou áudio, obter uma estimativa
calórica gerada por IA (mock no MVP), permitir revisão/edição antes do salvamento e
exibir lista e total diário na tela inicial. Arquitetura offline‑first, persistência em
memória no MVP e adaptador de IA desacoplado para futura substituição por integração real.

## Technical Context

**Language/Version**: Flutter (Dart SDK compatible com Flutter 3.x ou superior)

**Primary Dependencies**: `flutter`, `flutter_test`, `speech_to_text` (adapter opcional),
pequena camada de estado (`ValueNotifier`/`ChangeNotifier`) — manter simples para MVP

**Storage**: Persistência em memória (lista em memória). Migração futura para
persistência local (SQLite / `sqflite`) prevista.

**Testing**: `flutter_test` para unidade e widget tests; testes manuais para fluxos de
permissões de áudio e revisão de IA.

**Target Platform**: Mobile (Android e iOS, Material 3 como base de design)

**Project Type**: mobile-app (Flutter)

**Performance Goals**: interface responsiva com 60fps em interações UI comuns; latência
da estimativa IA não bloqueante (usar loading e timeout curto no MVP).

**Constraints**: Offline‑First (o app DEVE funcionar sem internet para funcionalidades
essenciais). Internet apenas para consumo pontual de APIs de IA/LLM documentadas no plano.

**Scale/Scope**: MVP limitado a uso individual no dispositivo; baixa escala para armazenamento
local (memória) e sincronização opcional futura.

## UI & Design

O produto DEVE adotar uma paleta de cores sugestiva para nutrição e alimentação saudável,
consistente com Material 3 tokens. Diretrizes iniciais (MVP):

- **Princípios**: contraste acessível (AA mínimo 4.5:1 para texto normal), simplicidade,
  ícones claros e feedback visual imediato para ações (salvar, erro, carregando).
- **Paleta sugerida (exemplos hex)**:
  - `primary`: #2E7D32 (verde)
  - `onPrimary`: #FFFFFF
  - `primaryContainer`: #C8E6C9 (verde claro)
  - `secondary`: #FFA726 (laranja suave)
  - `onSecondary`: #000000
  - `background`: #FFFDF6 (creme suave)
  - `surface`: #FFFFFF
  - `success`: #43A047 (verde folha)
  - `warning`: #FFB300 (âmbar)
  - `error`: #B00020

- **Tokens Material 3**: gerar `ColorScheme` a partir da cor seed (`primary`) e expor tokens
  para `primary`, `onPrimary`, `background`, `surface`, `error`, `secondary`, `onSecondary`.
- **Acessibilidade**: validar contrastes com ferramenta automatizada; fornecer variantes
  de alto contraste para leitura e para cores em gráficos.
- **Componentes**: botões principais usem `primary`, botões secundários `secondary`; badges
  e indicadores de sucesso usem `success`. Use tipografia consistente via `ThemeData`.

Racional: paleta verde + tom quente (laranja) comunica saúde e apetite controlado; tokens
facilitam substituição e testes de contraste.

## Constitution Check

Gates avaliadas contra `.specify/memory/constitution.md` v2.1.0:

- **Idioma**: PASS — todos os artefatos desta feature estão em português do Brasil.
- **Simplicidade**: PASS — abordagem mínima (persistência em memória, estado simples).
- **Offline First**: PASS com condição — o plano documenta que internet só será usada
  para chamadas IA/LLM e que esse uso será explícito e justificado no plano técnico.
- **IA / Privacidade**: PASS com ação — implementar na Phase 2 um checklist de privacidade
  e esclarecer armazenamento de chaves/consentimento; para MVP, usar adaptador mock.

Revisão obrigatória: `plan.md` deve descrever o adaptador de IA (interface) e a estratégia
de degradabilidade quando a IA não estiver disponível.

## Project Structure

### Documentation (this feature)

```text
specs/001-home-adicionar-refeicao-ia/
├── plan.md                      # Este arquivo
├── research.md                  # Fase 0 — pesquisa sobre transcrição, IA e permissões ✓
├── data-model.md                # Fase 1 — entidades e tipos ✓
├── quickstart.md                # Fase 1 — validação rápida/como testar ✓
├── contracts/
│   └── ai_adapter.md            # Fase 1 — contrato interface AiAdapter ✓
└── tasks.md                     # Fase 2 — gerado por /speckit.tasks ✓
```

### Source Code (proposta minimalista para Flutter em /app)

```text
app/
├── lib/
│   ├── main.dart
│   ├── features/
│   │   └── home/
│   │       ├── home_page.dart
│   │       ├── add_meal_page.dart
│   │       ├── widgets/
│   │       └── view_model.dart  # ChangeNotifier / ValueNotifier
│   ├── services/
│   │   ├── ai_adapter/
│   │   │   ├── ai_adapter.dart   # interface/abstração
│   │   │   └── ai_adapter_mock.dart
│   │   └── speech/
│   │       └── speech_service.dart
│   └── models/
│       └── meal.dart
└── test/
    ├── unit/
    └── widget/
```

**Structure Decision**: monorepo com todo código da aplicação Flutter concentrado em `app/`.
O módulo `home` e os serviços desacoplados (`ai_adapter`, `speech`) vivem em `app/lib/`.
O adaptador IA permanece como interface pública com implementação mock no MVP.

## Complexity Tracking

Sem violações constitucionais que exijam justificativa MAJOR. Pequenas condições (privacidade
de IA, degradabilidade) estão tratadas por tarefas no Phase 0/1.

## Phase 0 — Research ✓ Concluído

1. ✓ Transcrição de áudio: decisão por `speech_to_text` on-device no MVP.
2. ✓ Interface `AiAdapter` definida: `estimateCalories(text) → {descricaoInterpretada, calorias, nota, confidence}`.
3. ✓ Prompt/contrato: documentado em `contracts/ai_adapter.md`.
4. ✓ UX revisão: threshold `confidence < 0.7` dispara aviso e destaca campos editáveis.
5. ✓ Segurança: chaves NÃO armazenadas no app; integração real requer proxy/backend (fora do MVP).

Entregável: `research.md` — concluído.

## Phase 1 — Design & Contracts ✓ Concluído

1. ✓ `data-model.md` — entidade `Meal` com campos, validações e transições de estado.
2. ✓ `contracts/ai_adapter.md` — interface Dart com entrada, saída, erros e threshold de confiança.
3. ✓ `quickstart.md` — cenários de validação manual dos fluxos US1/US2/US3.
4. ✓ Design de UI — paleta Material 3 (seed `#2E7D32`) e tokens definidos no plano. Tema exemplo:
   `app/lib/themes/nutrition_theme.dart` (a criar na implementação).

### Re-check Constitution Check (pós Phase 1)

- **Idioma**: PASS — todos os artefatos em PT-BR.
- **Simplicidade**: PASS — mock, memória, ChangeNotifier; sem deps extras.
- **Offline First**: PASS — `speech_to_text` on-device; IA via mock sem internet.
- **Arquitetura**: PASS — camadas claras em `app/lib/` (features, services, models).
- **IA/Privacidade**: PASS — chave não armazenada no app; mock documentado.

## Phase 2 — Implementation ✓ Tasks geradas

Todos os entregáveis da Phase 2 ficam em `app/`:

- ✓ `tasks.md` — 30 tarefas PT-BR ordenadas por dependência.
- `app/lib/features/home/home_page.dart` — tela Home com total diário e lista.
- `app/lib/features/home/add_meal_page.dart` — tela Adicionar Refeição.
- `app/lib/services/ai_adapter/ai_adapter.dart` — interface.
- `app/lib/services/ai_adapter/ai_adapter_mock.dart` — implementação mock.
- `app/lib/services/speech/speech_service.dart` — wrapper `speech_to_text`.
- `app/lib/models/meal.dart` — entidade Meal.
- `app/lib/themes/nutrition_theme.dart` — tema Material 3.
- `app/test/` — testes unitários e widget tests.

### Portões de Qualidade (a validar ao concluir cada tarefa)

```bash
cd app
dart format .
flutter analyze
flutter test
```

---

**Plan author**: speckit.plan automation

