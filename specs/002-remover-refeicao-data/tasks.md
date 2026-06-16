# Tasks: Remover refeição e navegar por data

**Branch**: `002-remover-refeicao-data` | **Date**: 2026-06-15 | **Plan**: ../plan.md

**Generated from**: Implementation Plan Phase 2 decomposition

---

## Phases Overview

| Phase | Objetivo | Tasks | Status |
|-------|----------|-------|--------|
| Phase 0 | Setup & Infrastructure | T001-T005, T001a | completed |
| Phase 1 | Foundational (ViewModel Extension) | T006-T012 | completed |
| Phase 2 | User Story 1 (Navegação por Data) | T013-T025 | in-progress |
| Phase 3 | User Story 2 (Remoção com Confirmação) | T026-T035, T031a | in-progress |
| Phase 4 | User Story 3 (Estado Vazio) | T036-T040 | in-progress |
| Phase 5 | Polish & Validation | T041-T047 | in-progress |

---

## Phase 0 — Setup & Infrastructure

### T001: Add `intl` dependency to pubspec.yaml
- **Type**: Infrastructure
- **Description**: Adicionar package `intl` para formatação de data localizada em português
- **Files Modified**: `app/pubspec.yaml`
- **Acceptance Criteria**:
  - ✓ `intl: ^0.19.0` adicionado em dependencies
  - ✓ `flutter pub get` executado com sucesso
  - ✓ Nenhum erro de versionamento com `intl`
- **Dependencies**: None (first task)
- **Effort**: 5 min

### T001a: Quality gate — Code formatting and analysis (Early validation) [P]
- **Type**: Quality Gate
- **Description**: Executar `dart format` e `flutter analyze` em baseline antes de iniciar lógica (constitution XII)
- **Files**: app/lib/ e app/test/
- **Commands**:
  ```bash
  dart format app/lib app/test --set-exit-if-changed
  flutter analyze
  ```
- **Acceptance Criteria**:
  - ✓ `dart format` retorna exit code 0
  - ✓ `flutter analyze` retorna 0 erros
  - ✓ Máximo 2 info-level hints aceitáveis
- **Dependencies**: T001
- **Effort**: 5 min

### T002: Create DateTimeExtensions utility (toLocalDate)
- **Type**: Infrastructure
- **Description**: Criar extension method `DateTime.toLocalDate()` para comparação de data sem hora
- **Files Created**: `app/lib/utils/datetime_extensions.dart`
- **Code Snippet**:
  ```dart
  extension DateTimeExtensions on DateTime {
    DateTime toLocalDate() {
      return DateTime(year, month, day);
    }
  }
  ```
- **Acceptance Criteria**:
  - ✓ Extension definida e testável
  - ✓ Sem erros de análise
  - ✓ Importação disponível em toda codebase
- **Dependencies**: None
- **Effort**: 10 min

### T003: Update Meal.create() to accept dataSelecionada parameter [P]
- **Type**: Foundational
- **Description**: Estender `Meal.create()` factory para aceitar `dataSelecionada` e ajustar timestamp
- **Files Modified**: `app/lib/models/meal.dart`
- **Code Changes**:
  - Adicionar parâmetro `required DateTime dataSelecionada` ao factory
  - Calcular `timestampAjustado = DateTime(dataSelecionada.year, ..., agora.hour, ...)`
  - Usar `timestampAjustado` ao criar Meal
- **Acceptance Criteria**:
  - ✓ Factory compila com novo parâmetro
  - ✓ Validações de data não permitem futuro
  - ✓ Timestamp ajustado mantém hora local
  - ✓ Tests de Meal.create() passam
- **Dependencies**: T002 (datetime_extensions)
- **Effort**: 15 min

### T004: Update AddMealPage to pass dataSelecionada to Meal.create() [P]
- **Type**: Integration
- **Description**: Modificar `AddMealPage` para passar `dataSelecionada` do ViewModel ao criar Meal
- **Files Modified**: `app/lib/features/home/add_meal_page.dart`
- **Code Changes**:
  - Acessar `vm.dataSelecionada` (propriedade que será adicionada em Phase 1)
  - Passar como parâmetro a `vm.addMeal(..., dataSelecionada: vm.dataSelecionada)`
- **Acceptance Criteria**:
  - ✓ Refeições adicionadas em data não-hoje ficam vinculadas a essa data
  - ✓ Sem erros de compilação
- **Dependencies**: T003, T006 (ViewModel.dataSelecionada)
- **Effort**: 10 min

### T005: Create test helper for DateTime mocking in tests
- **Type**: Testing Infrastructure
- **Description**: Criar helper para mockar DateTime.now() em testes de navegação
- **Files Created**: `app/test/helpers/date_time_mock_helper.dart`
- **Code Snippet**:
  ```dart
  DateTime mockToday(DateTime date) {
    // Mock implementation for testing with specific dates
    return date;
  }
  ```
- **Acceptance Criteria**:
  - ✓ Helper disponível em test files
  - ✓ Permite testar lógica de navegação sem depender de data real
- **Dependencies**: None
- **Effort**: 15 min

---

## Phase 1 — Foundational (ViewModel Extension)

### T006: Add dataSelecionada property to HomeViewModel
- **Type**: State Management
- **Description**: Adicionar `DateTime dataSelecionada` ao `HomeViewModel`, inicializado com hoje
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  class HomeViewModel extends ChangeNotifier {
    DateTime dataSelecionada = DateTime.now();
    // ... resto do código
  }
  ```
- **Acceptance Criteria**:
  - ✓ Propriedade inicializa com `DateTime.now()` (hoje)
  - ✓ Alterações a `dataSelecionada` disparam `notifyListeners()`
  - ✓ Sem erros de compilação
- **Dependencies**: None
- **Effort**: 5 min

### T007: Implement mealsDoDia getter (filter by date)
- **Type**: State Management
- **Description**: Criar getter `mealsDoDia` que filtra `_meals` pela data selecionada
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  List<Meal> get mealsDoDia {
    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    return _meals
        .where((m) => m.timestamp.year == yyyy && 
                      m.timestamp.month == mm && 
                      m.timestamp.day == dd)
        .toList();
  }
  ```
- **Acceptance Criteria**:
  - ✓ Getter retorna lista vazia se nenhuma refeição da data
  - ✓ Getter retorna apenas refeições de `dataSelecionada`
  - ✓ Filtragem O(n) aceitável para MVP
- **Dependencies**: T002, T006
- **Effort**: 10 min

### T008: Update totalHoje getter to use mealsDoDia [P]
- **Type**: State Management
- **Description**: Refatorar `totalHoje` para calcular total apenas de `mealsDoDia` (não global)
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  int get totalHoje {
    return mealsDoDia.fold(0, (sum, meal) => sum + meal.calorias);
  }
  ```
- **Acceptance Criteria**:
  - ✓ Total calculado por data selecionada
  - ✓ Retorna 0 se `mealsDoDia` vazio
  - ✓ Testes de `totalHoje` passam
- **Dependencies**: T007
- **Effort**: 5 min

### T009: Implement podeVoltar computed property
- **Type**: State Management
- **Description**: Criar getter `podeVoltar` (sempre true, sem limite inferior)
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  bool get podeVoltar => true;
  ```
- **Acceptance Criteria**:
  - ✓ Sempre retorna true
  - ✓ Disponível para UI usar
- **Dependencies**: T006
- **Effort**: 2 min

### T010: Implement podeAvancar computed property
- **Type**: State Management
- **Description**: Criar getter `podeAvancar` (true apenas se `dataSelecionada < hoje`)
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  bool get podeAvancar {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada.toLocalDate().isBefore(hoje);
  }
  ```
- **Acceptance Criteria**:
  - ✓ Retorna false quando `dataSelecionada == hoje`
  - ✓ Retorna true para datas passadas
  - ✓ Protege contra navegação futura
- **Dependencies**: T002, T006
- **Effort**: 5 min

### T011: Implement eHoje computed property
- **Type**: State Management
- **Description**: Criar getter `eHoje` para indicar se `dataSelecionada == hoje`
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  bool get eHoje {
    final hoje = DateTime.now().toLocalDate();
    return dataSelecionada.toLocalDate() == hoje;
  }
  ```
- **Acceptance Criteria**:
  - ✓ Retorna true apenas quando data == hoje
  - ✓ Usado em UI para destaque visual
- **Dependencies**: T002, T006
- **Effort**: 5 min

### T012: Unit tests for ViewModel date properties [P]
- **Type**: Testing
- **Description**: Testar propriedades `podeVoltar`, `podeAvancar`, `eHoje` com datas variadas
- **Files Created**: `app/test/unit/us2_date_navigation_test.dart`
- **Test Scenarios**:
  - ✓ `podeAvancar` false em hoje
  - ✓ `podeAvancar` true em data passada
  - ✓ `eHoje` true apenas em hoje
  - ✓ `podeVoltar` sempre true
- **Acceptance Criteria**:
  - ✓ 4/4 testes passam
  - ✓ `flutter test` não relata erros
- **Dependencies**: T005, T009, T010, T011
- **Effort**: 20 min

---

## Phase 2 — User Story 1 (Navegação por Data)

### T013: Implement voltarDia() method
- **Type**: State Management
- **Description**: Implementar ação de voltar um dia
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  void voltarDia() {
    dataSelecionada = dataSelecionada.subtract(Duration(days: 1));
    notifyListeners();
  }
  ```
- **Acceptance Criteria**:
  - ✓ Decrementa `dataSelecionada` em 1 dia
  - ✓ Dispara `notifyListeners()` para atualizar UI
  - ✓ Sem limite inferior (pode voltar meses)
- **Dependencies**: T006
- **Effort**: 5 min

### T014: Implement avancarDia() method with future date protection
- **Type**: State Management
- **Description**: Implementar ação de avançar um dia com bloqueio de datas futuras
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  void avancarDia() {
    if (podeAvancar) {
      dataSelecionada = dataSelecionada.add(Duration(days: 1));
      notifyListeners();
    }
  }
  ```
- **Acceptance Criteria**:
  - ✓ Incrementa data apenas se `podeAvancar`
  - ✓ Silenciosamente ignora se em hoje
  - ✓ Dispara `notifyListeners()` apenas se avançou
- **Dependencies**: T010, T013
- **Effort**: 5 min

### T015: Implement voltarParaHoje() method
- **Type**: State Management
- **Description**: Implementar ação de retornar para hoje
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  void voltarParaHoje() {
    dataSelecionada = DateTime.now().toLocalDate();
    notifyListeners();
  }
  ```
- **Acceptance Criteria**:
  - ✓ Define `dataSelecionada = hoje` sempre
  - ✓ Dispara `notifyListeners()`
- **Dependencies**: T002, T006
- **Effort**: 5 min

### T016: Create DateNavigationBar widget
- **Type**: UI
- **Description**: Novo widget para exibir data e controles de navegação (anterior, hoje, próximo)
- **Files Created**: `app/lib/features/home/widgets/date_navigation_bar.dart`
- **Structure**:
  - Row com 3 botões: `< Anterior`, `Hoje`, `> Próximo`
  - Exibe data selecionada centralizada no topo
  - Botão próximo desabilitado quando `!podeAvancar`
  - Botão hoje com destaque visual se `!eHoje`
- **Acceptance Criteria**:
  - ✓ Widget compila e renderiza
  - ✓ Botões chamam métodos corretos do ViewModel
  - ✓ Estados desabilitados aplicados corretamente
  - ✓ Sem erros de análise
- **Dependencies**: T013, T014, T015
- **Effort**: 25 min

### T017: Format and display date in DateNavigationBar
- **Type**: UI
- **Description**: Integrar formatação de data com `intl` no header (ex: "seg, 15 de junho")
- **Files Modified**: `app/lib/features/home/widgets/date_navigation_bar.dart`
- **Code Snippet**:
  ```dart
  import 'package:intl/intl.dart';

  final formatter = DateFormat('EEEE, d de MMMM', 'pt_BR');
  Text(formatter.format(dataSelecionada))
  ```
- **Acceptance Criteria**:
  - ✓ Data formatada em português
  - ✓ Atualiza quando `dataSelecionada` muda
  - ✓ Sem caracteres quebrados ou codificação incorreta
- **Dependencies**: T001, T016
- **Effort**: 10 min

### T018: Integrate DateNavigationBar into HomePage
- **Type**: UI Integration
- **Description**: Adicionar `DateNavigationBar` no topo de `HomePage` acima da lista de refeições
- **Files Modified**: `app/lib/features/home/home_page.dart`
- **Layout**:
  ```
  [DateNavigationBar]
  [Total de Calorias]
  [Lista de Refeições / Estado Vazio]
  ```
- **Acceptance Criteria**:
  - ✓ `DateNavigationBar` renderizado no topo
  - ✓ Sem layout conflicts com components existentes
  - ✓ HomePage compila sem erros
- **Dependencies**: T016
- **Effort**: 10 min

### T019: Update totalHoje display to be date-specific [P]
- **Type**: UI
- **Description**: Modificar exibição de `totalHoje` para deixar claro que é da data selecionada
- **Files Modified**: `app/lib/features/home/home_page.dart`
- **Changes**:
  - Label: "Total de hoje" → "Total do dia: {totalHoje} kcal"
  - Opcional: exibir data selecionada perto do total
- **Acceptance Criteria**:
  - ✓ Label reflete data selecionada
  - ✓ Atualiza quando data ou refeições mudam
- **Dependencies**: T018
- **Effort**: 5 min

### T020: Widget test for date navigation (T006-T015)
- **Type**: Testing
- **Description**: Testar navegação entre datas: voltar, avançar até hoje, voltar para hoje
- **Files Created**: `app/test/widget/us1_date_navigation_test.dart`
- **Scenarios**:
  - ✓ Abrir app exibe data hoje
  - ✓ Pressionar "< Anterior" muda data e lista
  - ✓ Pressionar "> Próximo" até hoje bloqueia
  - ✓ Pressionar "Hoje" volta para hoje
- **Acceptance Criteria**:
  - ✓ Todos cenários passam
  - ✓ `flutter test` retorna 0 erros
- **Dependencies**: T005, T013, T014, T015, T016
- **Effort**: 30 min

### T021: Integration test for date navigation + meal list consistency [P]
- **Type**: Testing
- **Description**: Testar que lista de refeições atualiza corretamente ao navegar datas
- **Files Modified**: `app/test/widget/us1_date_navigation_test.dart`
- **Scenarios**:
  - ✓ Navegar para data sem refeições exibe lista vazia
  - ✓ Navegar para data com refeições exibe lista correta
  - ✓ Total recalculado para cada data
- **Acceptance Criteria**:
  - ✓ Integração entre ViewModel e UI validada
  - ✓ Testes passam
- **Dependencies**: T007, T008, T020
- **Effort**: 25 min

### T022: Edge case test: rapid date navigation
- **Type**: Testing
- **Description**: Testar que navegação rápida entre datas não mistura refeições
- **Files Created**: `app/test/unit/edge_cases_test.dart`
- **Scenario**:
  - Navegar: hoje → -2 dias → -5 dias → +3 dias → hoje em rápida sequência
  - Validar que lista sempre mostra refeições corretas da data
- **Acceptance Criteria**:
  - ✓ Nenhuma mistura de dados entre datas
  - ✓ Teste passa
- **Dependencies**: T007, T021
- **Effort**: 20 min

### T023: Edge case test: timestamp preservation across dates
- **Type**: Testing
- **Description**: Validar que refeições criadas em data não-hoje mantêm timestamp correto
- **Files Created**: `app/test/unit/timestamp_test.dart`
- **Scenario**:
  - Criar refeição em 14 de junho enquanto `dataSelecionada = 14 jun`
  - Navegar para 15 de junho e verificar refeição não aparece
  - Navegar de volta para 14 de junho e verificar refeição aparece
- **Acceptance Criteria**:
  - ✓ Refeição fica vinculada à data de criação
  - ✓ Filtragem funciona corretamente
- **Dependencies**: T003, T004, T007
- **Effort**: 20 min

### T024: Manual smoke test for date navigation (per quickstart.md Scenario 1)
- **Type**: Manual Testing
- **Description**: Executar Scenario 1 de quickstart.md no emulador Android
- **Test Steps**:
  - Abrir app, verificar data hoje
  - Navegar anterior 3 vezes, avançar 2 vezes, voltar para hoje
  - Verificar transições < 1 segundo
- **Success Criteria**:
  - ✓ Nenhum crash
  - ✓ Navegação responsiva
  - ✓ Lista atualiza corretamente
- **Dependencies**: T018, T020, T021
- **Effort**: 15 min

### T025: Manual test for multi-day data isolation (per quickstart.md Scenario 2) [P]
- **Type**: Manual Testing
- **Description**: Executar Scenario 2 de quickstart.md (adicionar refeições em 2 datas, validar isolamento)
- **Test Steps**:
  - Adicionar 2 refeições em 14 de junho
  - Adicionar 3 refeições em 15 de junho (hoje)
  - Navegar entre datas, verificar totais por data
- **Success Criteria**:
  - ✓ Totais calculados por data
  - ✓ Listas não misturadas
- **Dependencies**: T024
- **Effort**: 20 min

---

## Phase 3 — User Story 2 (Remoção com Confirmação)

### T026: Implement getMealById() method in HomeViewModel
- **Type**: State Management
- **Description**: Adicionar método para buscar refeição por ID no ViewModel
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  Meal? getMealById(String id) {
    try {
      return _meals.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
  ```
- **Acceptance Criteria**:
  - ✓ Retorna Meal se encontrada
  - ✓ Retorna null se não encontrada
  - ✓ Sem exceções não-capturadas
- **Dependencies**: T006
- **Effort**: 5 min

### T027: Implement confirmarRemocao() method
- **Type**: State Management
- **Description**: Implementar método que remove refeição validando data selecionada
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  void confirmarRemocao(String mealId) {
    final meal = getMealById(mealId);
    if (meal == null) {
      errorMessage = 'Refeição não encontrada';
      notifyListeners();
      return;
    }
    
    final yyyy = dataSelecionada.year;
    final mm = dataSelecionada.month;
    final dd = dataSelecionada.day;
    if (!(meal.timestamp.year == yyyy &&
          meal.timestamp.month == mm &&
          meal.timestamp.day == dd)) {
      errorMessage = 'Refeição não pertence à data selecionada';
      notifyListeners();
      return;
    }
    
    _repository.remove(mealId);
    _meals = _repository.getAll();
    errorMessage = null;
    notifyListeners();
  }
  ```
- **Acceptance Criteria**:
  - ✓ Remove refeição da data selecionada
  - ✓ Rejeita remoção de refeição de outro dia
  - ✓ Dispara `notifyListeners()` após remoção
  - ✓ Atualiza `totalHoje`
- **Dependencies**: T007, T008, T026
- **Effort**: 15 min

### T028: Implement cancelarRemocao() method
- **Type**: State Management
- **Description**: Implementar método para cancelar remoção (fecha dialog)
- **Files Modified**: `app/lib/features/home/view_model.dart`
- **Code Changes**:
  ```dart
  void cancelarRemocao() {
    // Dialog será fechado pelo widget; aqui apenas reseta flag se necessário
  }
  ```
- **Acceptance Criteria**:
  - ✓ Método disponível para chamar do widget
  - ✓ Sem side-effects em `_meals`
- **Dependencies**: T006
- **Effort**: 2 min

### T029: Create MealRemovalDialog widget
- **Type**: UI
- **Description**: Novo widget AlertDialog para confirmação de remoção
- **Files Created**: `app/lib/features/home/widgets/meal_removal_dialog.dart`
- **Structure**:
  - Title: "Remover refeição?"
  - Content: "Esta ação não pode ser desfeita."
  - Buttons: "Cancelar", "Remover"
- **Acceptance Criteria**:
  - ✓ Dialog compila e renderiza
  - ✓ Botões disparados corretamente
  - ✓ Sem erros de análise
- **Dependencies**: None
- **Effort**: 15 min

### T030: Add long-press and delete icon to meal list items
- **Type**: UI
- **Description**: Modificar widgets de item de refeição para suportar long-press e ícone de deletar
- **Files Modified**: `app/lib/features/home/widgets/meal_list_item.dart` (novo) ou `home_page.dart`
- **Changes**:
  - Long-press dispara `showDialog()` com `MealRemovalDialog`
  - Ícone de lixo ao lado de cada item para delete alternativo
- **Acceptance Criteria**:
  - ✓ Long-press exibe dialog
  - ✓ Ícone deletar exibe dialog
  - ✓ Dialog passado com `mealId`
- **Dependencies**: T029
- **Effort**: 20 min

### T031: Connect dialog to ViewModel actions (confirmarRemocao/cancelarRemocao)
- **Type**: UI Integration
- **Description**: Integrar `MealRemovalDialog` com métodos `confirmarRemocao()` e `cancelarRemocao()` do ViewModel
- **Files Modified**: `app/lib/features/home/widgets/meal_removal_dialog.dart`, `home_page.dart`
- **Code Changes**:
  ```dart
  TextButton(
    onPressed: () {
      Navigator.pop(context);
      vm.confirmarRemocao(mealId);
    },
    child: Text('Remover'),
  )
  ```
- **Acceptance Criteria**:
  - ✓ Clicar "Remover" chama `confirmarRemocao()`
  - ✓ Clicar "Cancelar" chama `cancelarRemocao()` e fecha dialog
  - ✓ List atualiza após remoção
  - ✓ Total recalculado
- **Dependencies**: T027, T028, T029, T030
- **Effort**: 15 min

### T031a: Display error messages in HomePage [P]
- **Type**: UI
- **Description**: Renderizar banner com mensagens de erro quando `vm.errorMessage` não-nulo (constitution V UX requirement)
- **Files Modified**: `app/lib/features/home/home_page.dart`
- **Code Snippet**:
  ```dart
  if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
    Container(
      color: Colors.red.shade100,
      padding: EdgeInsets.all(12),
      child: Text(vm.errorMessage!),
    )
  }
  ```
- **Acceptance Criteria**:
  - ✓ Error banner renderizado quando `errorMessage` definida
  - ✓ Banner desaparece quando `errorMessage` é null
  - ✓ Sem erros de compilação
- **Dependencies**: T027, T031
- **Effort**: 10 min

### T032: Unit test for confirmarRemocao() with data validation [P]
- **Type**: Testing
- **Description**: Testar `confirmarRemocao()` com refeição da data e de outra data
- **Files Created**: `app/test/unit/us2_meal_removal_test.dart`
- **Scenarios**:
  - ✓ Remove refeição da data selecionada com sucesso
  - ✓ Rejeita remoção de refeição de outro dia
  - ✓ Rejeita remoção de refeição inexistente
  - ✓ `totalHoje` atualizado após remoção
- **Acceptance Criteria**:
  - ✓ 4/4 testes passam
  - ✓ Data isolation validada
- **Dependencies**: T005, T027
- **Effort**: 25 min

### T033: Widget test for meal removal dialog and list update
- **Type**: Testing
- **Description**: Testar fluxo de remoção: long-press → dialog → confirmar → lista atualiza
- **Files Created**: `app/test/widget/us2_meal_removal_test.dart`
- **Scenarios**:
  - ✓ Long-press exibe dialog
  - ✓ Cancelar fecha dialog sem remover
  - ✓ Confirmar remove item e atualiza lista/total
  - ✓ Última refeição removida exibe estado vazio
- **Acceptance Criteria**:
  - ✓ Todos cenários passam
  - ✓ `flutter test` retorna 0 erros
- **Dependencies**: T032, T029, T030
- **Effort**: 30 min

### T034: Edge case test: removal idempotence (rapid clicks)
- **Type**: Testing
- **Description**: Testar que cliques rápidos múltiplos no botão remover não causam crash
- **Files Created**: `app/test/unit/edge_cases_removal_test.dart`
- **Scenario**:
  - Dialog exibido, cliques rápidos no botão remover
  - Validar que apenas 1 remoção ocorre
- **Acceptance Criteria**:
  - ✓ Nenhum crash
  - ✓ Refeição removida exatamente 1 vez
- **Dependencies**: T033
- **Effort**: 15 min

### T035: Manual smoke test for meal removal (per quickstart.md Scenario 3) [P]
- **Type**: Manual Testing
- **Description**: Executar Scenario 3 de quickstart.md no emulador
- **Test Steps**:
  - Adicionar 2+ refeições
  - Long-press em uma, cancelar (sem remover)
  - Long-press em outra, confirmar (remove)
  - Verificar lista e total atualizados
- **Success Criteria**:
  - ✓ Nenhum crash
  - ✓ Remoção funciona
  - ✓ Cancelamento preserva lista
- **Dependencies**: T033
- **Effort**: 15 min

---

## Phase 4 — User Story 3 (Estado Vazio por Data)

### T036: Create EmptyStateWidget for date-specific messages
- **Type**: UI
- **Description**: Novo widget que exibe estado vazio contextualizado à data selecionada
- **Files Created**: `app/lib/features/home/widgets/date_empty_state.dart`
- **Structure**:
  - Ícone de prato vazio
  - Mensagem: "Nenhuma refeição em {data formatada}"
- **Acceptance Criteria**:
  - ✓ Widget compila
  - ✓ Aceita `DateTime dataSelecionada`
  - ✓ Mensagem customizada por data
  - ✓ Sem erros de análise
- **Dependencies**: T001
- **Effort**: 15 min

### T037: Integrate EmptyStateWidget into HomePage
- **Type**: UI Integration
- **Description**: Exibir `EmptyStateWidget` quando `mealsDoDia.isEmpty`
- **Files Modified**: `app/lib/features/home/home_page.dart`
- **Code Logic**:
  ```dart
  if (mealsDoDia.isEmpty) {
    DateEmptyStateWidget(dataSelecionada: dataSelecionada)
  } else {
    ListView(...)
  }
  ```
- **Acceptance Criteria**:
  - ✓ Estado vazio exibido para data sem refeições
  - ✓ Transição suave entre estado vazio e lista
  - ✓ HomePage compila
- **Dependencies**: T036, T018
- **Effort**: 10 min

### T038: Unit test for empty state logic
- **Type**: Testing
- **Description**: Testar que `mealsDoDia.isEmpty` dispara estado vazio
- **Files Created**: `app/test/unit/us3_empty_state_test.dart`
- **Scenarios**:
  - ✓ `mealsDoDia` vazio em data sem refeições
  - ✓ `mealsDoDia` não-vazio após adicionar refeição
  - ✓ `mealsDoDia` vazio após remover última refeição
- **Acceptance Criteria**:
  - ✓ 3/3 testes passam
- **Dependencies**: T007
- **Effort**: 15 min

### T039: Widget test for empty state display
- **Type**: Testing
- **Description**: Testar que widget de estado vazio renderiza com mensagem correta
- **Files Created**: `app/test/widget/us3_empty_state_test.dart`
- **Scenarios**:
  - ✓ Navegar para data sem refeições exibe estado vazio
  - ✓ Mensagem contém data correta
  - ✓ Ícone renderizado
- **Acceptance Criteria**:
  - ✓ Testes passam
  - ✓ `flutter test` retorna 0 erros
- **Dependencies**: T038, T036
- **Effort**: 20 min

### T040: Manual test for empty state (per quickstart.md Scenario 5) [P]
- **Type**: Manual Testing
- **Description**: Executar Scenario 5 de quickstart.md no emulador
- **Test Steps**:
  - Navegar para data sem refeições
  - Verificar mensagem específica por data
  - Navegar para outra data vazia, verificar mensagem atualiza
- **Success Criteria**:
  - ✓ Estado vazio exibido
  - ✓ Mensagem clara e específica
- **Dependencies**: T039
- **Effort**: 10 min

### T046: Contract validation test (interface compliance)
- **Type**: Testing (Quality Gate)
- **Description**: Validar que todos métodos e propriedades do HomeViewModel correspondem assinaturas em contracts/date-navigation.md e contracts/meal-removal.md
- **Files Created**: `app/test/unit/contracts_compliance_test.dart`
- **Test Scenarios**:
  - ✓ ViewModel expõe `podeVoltar`, `podeAvancar`, `eHoje` (bool getters)
  - ✓ ViewModel expõe `mealsDoDia`, `totalHoje` (List<Meal>, int getters)
  - ✓ ViewModel expõe `voltarDia()`, `avancarDia()`, `voltarParaHoje()` (void methods)
  - ✓ ViewModel expõe `getMealById(String)`, `confirmarRemocao(String)`, `cancelarRemocao()` (removal methods)
  - ✓ Method signatures match contract specifications exactly
- **Acceptance Criteria**:
  - ✓ Teste compila e executa
  - ✓ Não há exceções de signature mismatch
  - ✓ Interface compliance validada
- **Dependencies**: T009, T010, T011, T013, T014, T015, T026, T027, T028
- **Effort**: 15 min

### T047: Performance test for date transition (SC-002 validation) [P]
- **Type**: Testing (Quality Gate)
- **Description**: Validar que transição entre datas (filtro + notificação) completa em < 500ms (SC-002: "em até 1 segundo percebido")
- **Files Created**: `app/test/unit/performance_test.dart`
- **Test Scenario**:
  - Mock 100 refeições em datas variadas
  - Medir tempo de `voltarDia()` → UI rebuild
  - Assert tempo < 500ms
- **Acceptance Criteria**:
  - ✓ Teste executa com sucesso
  - ✓ Tempo de transição < 500ms em MVP volume
  - ✓ SC-002 validado automaticamente
- **Dependencies**: T012, T013, T014
- **Effort**: 20 min

---

## Phase 5 — Polish & Validation

### T041: Final code formatting and analysis (Phase 5 validation)
- **Type**: Quality Gate
- **Description**: Executar `dart format` e `flutter analyze` novamente em todos arquivos após implementação (validação final)
- **Files**: Todos em feature 002
- **Commands**:
  ```bash
  dart format app/lib/
  flutter analyze
  ```
- **Acceptance Criteria**:
  - ✓ `dart format` aplica sem erros
  - ✓ `flutter analyze` retorna 0 erros
  - ✓ Máximo 2 info-level hints aceitáveis
- **Dependencies**: T040, T046, T047
- **Effort**: 5 min

### T042: Run full test suite
- **Type**: Quality Gate
- **Description**: Executar `flutter test` para validar todos unit e widget tests
- **Command**:
  ```bash
  flutter test
  ```
- **Acceptance Criteria**:
  - ✓ Todos testes passam (100%)
  - ✓ Coverage: core ViewModel + UI > 80%
  - ✓ Sem flaky tests
- **Dependencies**: T012, T020, T032, T033, T038, T039
- **Effort**: 30 min

### T043: Manual end-to-end validation (complete quickstart.md)
- **Type**: Manual Testing
- **Description**: Executar todos 5 cenários de quickstart.md em sequência no emulador
- **Scenarios**:
  1. ✓ Date Navigation (T024)
  2. ✓ Multi-Day Isolation (T025)
  3. ✓ Meal Removal (T035)
  4. ✓ Timestamp Adjustment (não há task específica; coberto por T023)
  5. ✓ Empty State (T040)
- **Acceptance Criteria**:
  - ✓ Todos 5 cenários executados
  - ✓ Nenhum crash ou comportamento inesperado
  - ✓ UX fluido e responsivo
- **Dependencies**: T024, T025, T035, T040
- **Effort**: 45 min

### T044: Update documentation (plan.md, research.md status)
- **Type**: Documentation
- **Description**: Marcar Phase 0-1 como complete, Phase 2-5 como executing/complete
- **Files Modified**: `specs/002-remover-refeicao-data/plan.md`
- **Changes**:
  - Phase 0 (Setup): ✓ COMPLETE
  - Phase 1 (Foundational): ✓ COMPLETE
  - Phase 2-5: → COMPLETE após conclusão
- **Acceptance Criteria**:
  - ✓ Status documentado
- **Dependencies**: T043
- **Effort**: 5 min

### T045: Git commit of feature 002 implementation
- **Type**: Version Control
- **Description**: Commitar código implementado com mensagem descritiva
- **Commit Message**:
  ```
  feat(feature-002): implementar navegação por data e remoção de refeição
  
  - Adicionar DateNavigationBar com controles de navegação
  - Implementar filtragem de refeições por data selecionada
  - Adicionar remoção com confirmação dialog
  - Exibir estado vazio específico por data
  - Proteger contra navegação para datas futuras
  
  Closes: Feature 002 User Stories 1-3
  ```
- **Acceptance Criteria**:
  - ✓ Todos arquivos staged
  - ✓ Commit sucesso com mensagem clara
  - ✓ Tests e análise passam
- **Dependencies**: T043
- **Effort**: 5 min

---

## Task Dependencies Summary

**Critical Path** (minimum path to completion):
```
T001 → T002 → T003 → T006 → T007 → T008 → T013 → T014 → T015 → T016 
→ T017 → T018 → T020 → T024 → T026 → T027 → T029 → T030 → T031 → T035 
→ T036 → T037 → T039 → T040 → T042 → T043 → T045
```

**Parallelizable Tasks** (can run in parallel):
- T009, T010, T011 (can run after T006)
- T012 (can run after T009, T010, T011)
- T013, T014, T015 (can run after T006)
- T026, T028 (can run after T006)
- T021, T022, T023 (can run after T007, T008)

---

**Consistency Review**: Analysis report integrated; corrections applied:
- ✓ C001: Quality gate moved to Phase 0 (T001a early validation)
- ✓ M001: Contract validation task added (T046, Phase 5)
- ✓ C002: Error display UI task added (T031a, Phase 3)
- ✓ S001: Performance test added (T047, Phase 5)

**Plan Status**: Phase 2 Task Decomposition COMPLETE | 49 tasks defined (45 base + 4 corrections) | Ready for implementation

---

## Execution Tracking (Implementação)

- [X] T001
- [X] T001a
- [X] T002
- [X] T003
- [X] T004
- [X] T005
- [X] T006
- [X] T007
- [X] T008
- [X] T009
- [X] T010
- [X] T011
- [X] T012
- [X] T013
- [X] T014
- [X] T015
- [X] T016
- [X] T017
- [X] T018
- [X] T019
- [X] T020
- [X] T021
- [X] T022
- [X] T023
- [ ] T024 (manual)
- [ ] T025 (manual)
- [X] T026
- [X] T027
- [X] T028
- [X] T029
- [X] T030
- [X] T031
- [X] T031a
- [X] T032
- [X] T033
- [X] T034
- [ ] T035 (manual)
- [X] T036
- [X] T037
- [X] T038
- [X] T039
- [ ] T040 (manual)
- [X] T041
- [X] T042
- [ ] T043 (manual)
- [ ] T044
- [ ] T045
- [X] T046
- [X] T047

