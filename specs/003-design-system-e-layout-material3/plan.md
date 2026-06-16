# Implementation Plan: Design System e Layout Material 3

**Branch**: `main` | **Date**: 2026-06-16 | **Spec**: ../spec.md

**Input**: Feature specification from `/specs/003-design-system-e-layout-material3/spec.md`

## Summary

Padronizar toda a experiência visual do app com Material 3 em tema claro, mantendo os fluxos já existentes (Home, adicionar por texto/áudio, revisão de estimativa, remoção com confirmação e navegação por data), sem introduzir novas funcionalidades de negócio. Além do design system, a estimativa da IA será estendida para retornar `iconKey`, `calorias` e `observacao`, com fallback para `default` quando o ícone não for suportado.

## Technical Context

**Language/Version**: Flutter/Dart (SDK >=3.0.0 <4.0.0; baseline do projeto 3.12+)

**Primary Dependencies**: `flutter`, `provider`, `intl`, `speech_to_text`, `uuid`

**Storage**: Repositório em memória (`InMemoryRepository`) no MVP

**Testing**: `flutter_test`, testes unitários e widget

**Target Platform**: Android e iOS (Material 3)

**Project Type**: Aplicativo mobile Flutter (cliente local)

**Performance Goals**: navegação e transições visuais fluidas a 60fps; render sem jank perceptível nos fluxos principais

**Constraints**: offline-first; sem backend novo; sem gráfico/metas/relatórios/gamificação; sem calendário mensal complexo

**Scale/Scope**: uma base mobile única (`app/`) com impacto em telas Home/Add/Review, tema e componentes reutilizáveis

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Justificativa |
|-----------|--------|---------------|
| I. Idioma | PASS | Artefatos em `specs/**` serão escritos em português do Brasil |
| II. Simplicidade | PASS | Reuso de telas/componentes existentes e tokens Material 3 sem reescrever arquitetura |
| III. Offline First | PASS | Ajustes de UI locais; IA permanece na camada já existente sem nova dependência de backend nesta feature |
| IV. Arquitetura | PASS | Alterações concentradas em presentation/domain model com contratos explícitos |
| V. UX | PASS | Poucos cliques, fluxo claro de adicionar/revisar/remover e estados vazios amigáveis |
| VI. Dados | PASS | Extensão mínima do modelo (`iconKey`) com fallback padrão |
| VII. Testabilidade | PASS | Regras de mapeamento de ícone e fallback cobertas por testes unitários/widget |
| VIII. IA | PASS | IA evolui sem aumentar complexidade de infraestrutura; apenas contrato de retorno |
| IX. MVP Primeiro | PASS | Sem novas features de produto, apenas padronização visual e adequação de retorno |
| X. Padrões Flutter/Dart | PASS | Material 3, widgets composáveis e lint/analyze mantidos |
| XI. Estado | PASS | Continuidade de `ChangeNotifier` + `Provider` |
| XII. Portões de Qualidade | PASS | Planejado rodar `dart format`, `flutter analyze`, `flutter test` |

**Resultado inicial**: PASS (sem violações)

## Project Structure

### Documentation (this feature)

```text
specs/003-design-system-e-layout-material3/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/
├── lib/
│   ├── features/
│   │   └── home/
│   │       ├── home_page.dart
│   │       ├── add_meal_page.dart
│   │       ├── view_model.dart
│   │       └── widgets/
│   ├── models/
│   │   └── meal.dart
│   ├── services/
│   │   ├── ai_adapter/
│   │   ├── audio_transcription/
│   │   └── repository/
│   ├── themes/
│   └── utils/
└── test/
    ├── unit/
    └── widget/
```

**Structure Decision**: manter a estrutura mobile existente em `app/`, introduzindo tokens e componentes visuais reutilizáveis sem criar novos módulos arquiteturais.

## Phase 0 — Research (output: `research.md`)

1. Definir tokens de design (cor, tipografia, espaçamento, raio, elevação) compatíveis com Material 3 e com a inspiração visual fornecida.
2. Definir comportamento de responsividade para telas pequenas e grandes sem novos fluxos de negócio.
3. Definir contrato de retorno de IA com `iconKey` + `calorias` + `observacao` e política de fallback (`default`) para ícones inválidos/ausentes.
4. Definir conjunto inicial de ícones suportados e mapeamento para widgets da lista Home.

## Phase 1 — Design & Contracts (outputs: `data-model.md`, `contracts/*`, `quickstart.md`)

1. Modelar entidades e regras (`Meal`, `AiEstimate`, `IconKey`) com validações de fallback.
2. Especificar contratos:
   - `contracts/design-system.md` (tokens e componentes reutilizáveis)
   - `contracts/ia-icon-key.md` (payload e regras de aceitação/fallback)
   - `contracts/responsive-layout.md` (comportamento por breakpoint)
3. Criar `quickstart.md` com roteiro de validação visual e funcional (texto + áudio + lista + remoção).

## Re-check Constitution (post Phase 1)

Após geração dos artefatos de design, os 12 princípios permanecem PASS; nenhum conflito identificado com simplicidade, offline-first, arquitetura e portões de qualidade.

## Complexity Tracking

Sem violações de constitution que exijam justificativa.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
