---
description: "Generated tasks for feature implementation"
---

# Tasks: Home e adicionar refeição com estimativa calórica por IA

**Input**: Design documents from `/specs/001-home-adicionar-refeicao-ia/`

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create Flutter skeleton files: lib/main.dart, pubspec.yaml, analysis_options.yaml
- [ ] T002 Create theme file `lib/themes/nutrition_theme.dart` (ColorScheme + tokens)
- [ ] T003 [P] Create test folders `test/unit/` and `test/widget/` and basic test harness

---

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 Create model `lib/models/meal.dart` with fields (id, descricao, calorias, timestamp, origem, ai_confidence, nota)
- [ ] T005 [P] Create AI adapter interface `lib/services/ai_adapter/ai_adapter.dart`
- [ ] T006 [P] Create AI adapter mock `lib/services/ai_adapter/ai_adapter_mock.dart`
- [ ] T007 [P] Create speech service abstraction `lib/services/speech/speech_service.dart` (on-device transcription hook)
- [ ] T008 [P] Create in-memory repository `lib/services/repository/in_memory_repository.dart` with CRUD for `Meal`
- [ ] T009 Implement `lib/features/home/view_model.dart` (ChangeNotifier) wiring models, repository and services
- [ ] T010 [P] Add basic app routing and shell in `lib/main.dart` (Home route + AddMeal route)

**Checkpoint**: Foundation complete — UI implementation for user stories can begin.

---

## Phase 3: User Story 1 - Registrar refeição por texto (Priority: P1) 🎯 MVP

**Goal**: Permitir adicionar refeição via campo de texto e salvar registro localmente com atualização do total diário.

**Independent Test**: Abrir Home -> Adicionar refeição (texto) -> solicitar estimativa IA -> revisar -> confirmar -> verificar lista e total.

- [ ] T011 [US1] Implement `lib/features/home/add_meal_page.dart` with text input UI and submit button
- [ ] T012 [P] [US1] Implement form widget `lib/features/home/widgets/meal_form.dart` (descricao, calorias editavel)
- [ ] T013 [US1] Implement save logic in `lib/features/home/view_model.dart` to add `Meal` to `in_memory_repository.dart`
- [ ] T014 [US1] Implement `lib/features/home/home_page.dart` to list meals and show daily total
- [ ] T015 [US1] Add widget test `test/widget/us1_add_meal_test.dart` validating add-by-text flow

---

## Phase 4: User Story 2 - Registrar refeição por áudio (Priority: P1)

**Goal**: Permitir gravação on-device, transcrição local e envio ao `AiAdapter` para estimativa.

**Independent Test**: Gravar áudio -> verificar transcrição -> solicitar estimativa -> revisar -> confirmar.

- [ ] T016 [US2] Integrate `lib/services/speech/speech_service.dart` into `lib/features/home/add_meal_page.dart` (record/stop)
- [ ] T017 [US2] Implement transcription handling and update form with transcribed text in `lib/features/home/view_model.dart`
- [ ] T018 [P] [US2] Add permission guidance and handling in `lib/features/home/add_meal_page.dart` (microphone permission flow)
- [ ] T019 [US2] Add widget test `test/widget/us2_audio_flow_test.dart` validating mocked transcription and UI flow

---

## Phase 5: User Story 3 - Revisar e editar sugestão da IA (Priority: P2)

**Goal**: Permitir revisão/edição da sugestão da IA, exibir aviso quando confiança baixa, permitir salvar mesmo assim.

**Independent Test**: Receber sugestão -> editar campos -> salvar -> verificar lista atualizada.

- [ ] T020 [US3] Implement review dialog `lib/features/home/widgets/review_suggestion_dialog.dart` (descricao + calorias editable)
- [ ] T021 [US3] Implement low-confidence UI `lib/features/home/widgets/confidence_warning.dart` and threshold logic in `lib/features/home/view_model.dart`
- [ ] T022 [US3] Add flow to allow saving despite low confidence (with conspicuous warning) in `lib/features/home/view_model.dart`
- [ ] T023 [US3] Add unit tests `test/unit/us3_review_tests.dart` for review/edit flows and low-confidence behavior

---

## Phase N: Polish & Cross-Cutting Concerns

- [ ] T024 [P] Update documentation in `specs/001-home-adicionar-refeicao-ia/quickstart.md` with validation steps
- [ ] T025 Code cleanup and lints (run formatter and analyzer) — apply to modified files
- [ ] T026 Add accessibility/contrast checks and high-contrast theme variant in `lib/themes/nutrition_theme.dart`
- [ ] T027 Add privacy checklist and notes about IA keys in `specs/001-home-adicionar-refeicao-ia/research.md`

---

## Dependencies & Execution Order

- Setup (Phase 1) → Foundational (Phase 2) → User Stories (Phase 3+) → Polish
- Within each story: models → services → viewmodels → UI → tests

## Parallel opportunities

- `T003`, `T005`, `T006`, `T007`, `T008`, `T010` marked `[P]` can be implemented in parallel by different devs
- Once Foundational completes, `US1` and `US2` tasks can proceed in parallel (subject to team size)

## Implementation Strategy

- MVP first: focus on Phase 3 (User Story 1) after Foundational. Deliver US1, validate, then add US2 (audio) and US3 (review/edit).

---

## Notes

- All tasks include explicit file paths to keep changes traceable.
- Tests are included as widget/unit stubs; implement details as needed.
