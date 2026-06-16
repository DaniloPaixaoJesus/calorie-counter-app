# Implementation Plan: Remover refeição e navegar por data

**Branch**: `002-remover-refeicao-data` | **Date**: 2026-06-15 | **Spec**: ../spec.md

**Input**: Feature specification from `/specs/002-remover-refeicao-data/spec.md`

## Summary

Estender a feature 001 adicionando navegação por data (anterior, próximo até hoje, voltar para hoje) com bloqueio de datas futuras, remover refeições com confirmação, e estados vazios por data. Aplicação offline-first, mesma arquitetura de memória do MVP e mantendo simplicidade.

## Technical Context

**Language/Version**: Flutter (Dart SDK 3.12+), mesmo que feature 001

**Primary Dependencies**: `flutter`, `provider` (já integrado em 001), `intl` (para formatação de data com localização PT-BR)

**Storage**: Persistência em memória (lista em memória com filtragem por data). Estrutura `Meal` já conta com `timestamp` (DateTime).

**Testing**: `flutter_test` para unidade e widget tests; testes manuais para navegação entre datas e validação de cálculo de total por data.

**Target Platform**: Mobile (Android e iOS, Material 3)

**Performance Goals**: Transição entre datas em < 1 segundo percebido; filtragem por data O(n) é aceitável para MVP.

**Constraints**: Offline-First (sem dependência de internet). Navegação bloqueada em datas futuras (máximo = hoje).

**Scale/Scope**: MVP limitado a uso individual no dispositivo; volume baixo de refeições permite filtragem simples por data.

## UI & Design

Estende a Home (feature 001) com:

- **Exibição de data**: header visível com data selecionada em formato legível (ex: "seg, 15 de junho de 2026").
- **Controles de navegação**: botões "< anterior", "hoje" (destaque se em data diferente de hoje), "> próximo" (desabilitado em hoje).
- **Indicador de estado**: total de calorias e lista filtrada por data; estado vazio específico por data quando não houver refeições.
- **Remoção com confirmação**: long-press ou ícone de deletar em cada item; dialog simples "Tem certeza?" antes de remover.
- **Consistência visual**: reusar paleta de cores e tokens Material 3 da feature 001; estado vazio exibe mensagem clara por data.

### Registro complementar (transcrição de áudio)

Para constar no plano técnico da spec 002: a alteração da estratégia de transcrição de áudio já foi implementada e testada nesta spec, mantendo aderência a simplicidade, MVP First, Offline First e desacoplamento da lógica de negócio.

Diretrizes comportamentais registradas:

- A gravação de áudio possui limite máximo de 30 segundos.
- O usuário precisa clicar explicitamente para parar a gravação.
- A interface deve exibir timer regressivo durante a gravação (30s até 0s).
- O texto transcrito deve ser exibido apenas após o término da gravação.

## Arquitetura de Decisão (Phase 0)

### AD-001: Representação da data selecionada

**Decisão**: Armazenar `dataSelecionada` como `DateTime` no `HomeViewModel` (apenas date, sem hora local).

**Rationale**: 
- Simplifica comparação com `DateTime.now()`.
- Compatível com filtro de refeições por data (comparar `meal.timestamp.toLocalDate()` com `dataSelecionada`).
- Permite bloqueio de navegação futura com verificação simples.

**Implementação**:
```dart
class HomeViewModel extends ChangeNotifier {
  DateTime dataSelecionada = DateTime.now(); // inicia com hoje
  // ...
}
```

### AD-002: Filtragem de refeições por data

**Decisão**: Filtrar `_meals` no getter por comparação de data (ano, mês, dia).

**Rationale**:
- O(n) é aceitável para MVP.
- Evita duplicação de dados (não armazenar refeições separadas por data).
- Facilita futura migração para banco de dados com índice.

**Implementação**:
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

### AD-003: Bloqueio de navegação para datas futuras

**Decisão**: Validar no método `avancarDia()` que `dataSelecionada + 1 dia <= hoje`; se não, manter `dataSelecionada` inalterada e desabilitar botão UI.

**Rationale**:
- Previne bugs de lógica (usuário não consegue adicionar refeições em datas futuras).
- Simplifica UX (botão desabilitado deixa claro o limite).
- Alinhado com clarificação da spec.

**Implementação**:
```dart
void avancarDia() {
  final proximo = dataSelecionada.add(Duration(days: 1));
  if (proximo.isBefore(DateTime.now().toLocalDate()) || 
      proximo.isAtSameMomentAs(DateTime.now().toLocalDate())) {
    dataSelecionada = proximo;
    notifyListeners();
  }
  // senão, silenciosamente ignora (botão já está desabilitado)
}

bool get podeAvancar => dataSelecionada.isBefore(DateTime.now().toLocalDate());
```

### AD-004: Armazenamento de `timestamp` ao adicionar em data não-hoje

**Decisão**: Ajustar `timestamp` no `Meal.create()` quando a data selecionada for diferente de hoje.

**Rationale**:
- Garante que cada refeição pertence ao dia certo na filtragem.
- Compatível com critério de aceite (refeição vinculada à data selecionada).
- Preserva hora local para futuras análises de timing de refeições.

**Implementação**:
```dart
factory Meal.create({
  required String descricao,
  required int calorias,
  required MealOrigem origem,
  required DateTime dataSelecionada,
  double? aiConfidence,
  String? nota,
}) {
  final agora = DateTime.now();
  final timestampAjustado = DateTime(
    dataSelecionada.year,
    dataSelecionada.month,
    dataSelecionada.day,
    agora.hour,
    agora.minute,
    agora.second,
  );
  return Meal(
    // ...
    timestamp: timestampAjustado,
    // ...
  );
}
```

### AD-005: Regra de captura de áudio com limite e exibição pós-finalização

**Decisão**: A captura de áudio adota limite técnico de 30 segundos, parada manual pelo usuário e exibição da transcrição apenas após o encerramento da gravação.

**Rationale**:
- Mantém fluxo simples e previsível para o MVP.
- Reduz risco de captura excessiva e ambiguidade de estado na UI.
- Melhora clareza da experiência com timer regressivo explícito.
- Preserva desacoplamento entre UI e mecanismo de transcrição.

**Regra de UX/Aplicação**:
- Início da gravação: inicia contador regressivo de 30 segundos.
- Durante gravação: somente timer e estado de captura são exibidos.
- Encerramento: ocorre por ação explícita do usuário ou por atingir 30 segundos.
- Pós-encerramento: exibir transcrição final consolidada; não exibir texto parcial durante captura.

## Constitution Check

Validação contra `.specify/memory/constitution.md`:

| Princípio | Status | Justificativa |
|-----------|--------|---------------|
| I. Idioma | ✓ | Spec e plano em português do Brasil |
| II. Simplicidade | ✓ | Filtragem O(n), sem agregações avançadas; estados simples |
| III. Offline First | ✓ | Sem dependência de internet; navegação e remoção 100% local |
| IV. Arquitetura | ✓ | ViewModel contém lógica; repositório desacoplado; widgets reutilizáveis |
| V. UX | ✓ | Navegação por 3 ações simples; confirmação antes de remover |
| VI. Dados | ✓ | Modelo de dados simples (timestamp já existe); sem sincronização |
| VII. Testabilidade | ✓ | Lógica de filtro, navigação e remoção testáveis; sem regra de negócio em widgets |
| VIII. IA | ✓ | Sem mudança; IA continua via `AiAdapter` de feature 001 |
| IX. MVP Primeiro | ✓ | Funcionalidade isolada, utilizável sem calendário mensal |
| X. Flutter/Dart | ✓ | Null safety, composição de widgets, formatação com `dart format` |
| XI. Gerenciamento de Estado | ✓ | `ChangeNotifier` + `Provider` (já consolidado em 001) |
| XII. Portões de Qualidade | ✓ | `flutter analyze`, `dart format`, testes, validação manual |

**Resultado**: PASSOU — feature alinhada com constituição do projeto.

## Phase 0 — Research (Tasks)

**Pesquisa a realizar:**

1. Integração com `intl` para formatação de data em português (ex: "segunda-feira, 15 de junho").
   - Deliverable: snippet de código para exibir data no formato esperado.

2. Validar suporte a DateTime.toLocalDate() equivalente em Dart (ou criar helper se necessário).
   - Deliverable: confirmação de sintaxe Dart para comparação de data sem hora.

3. UX de estado vazio: definir exatamente qual mensagem mostrar quando data não tiver refeições.
   - Deliverable: textos específicos (ex: "Nenhuma refeição em 15 de junho").

**Deliverable**: `research.md` com decisões.

## Phase 1 — Design & Contracts

**Artefatos a gerar:**

1. **`data-model.md`**:
   - Validações de `dataSelecionada` (não pode ser data futura dentro de add/remove).
   - Representação de "estado vazio" para uma data sem refeições.

2. **`contracts/date-navigation.md`**:
   - Interface de navegação: métodos `voltarDia()`, `avancarDia()`, `voltarParaHoje()`.
   - Estados visíveis: `podeVoltar`, `podeAvancar`.

3. **`contracts/meal-removal.md`**:
   - Interface de remoção: método `removerRefeicao(String id)` com confirmação.
   - Restrição: remoção afeta apenas o total da data da refeição.

4. **`quickstart.md`**:
   - Passos de validação manual:
     - Abrir app → Home mostra hoje.
     - Avançar 2 vezes → voltar para hoje → verificar lista muda.
     - Adicionar 2 refeições em dias diferentes → remover uma → verificar total do dia certo.

**Deliverable**: artefatos de design + `quickstart.md`.

---

**Plan author**: speckit.plan automation | **Status**: Draft | **Next**: Phase 0 Research
