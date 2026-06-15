# Feature Specification: Remover refeição e navegar por data

**Feature Branch**: `002-remover-refeicao-data`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "Criar a feature 'Remover refeição e navegar por data'"

## Clarifications

### Session 2026-06-15

- Q: Como vincular tecnicamente a refeição ao dia selecionado no salvamento? -> A: Ao salvar, ajustar `timestamp` para a data selecionada combinada com a hora local atual do dispositivo.
- Q: A navegação deve permitir datas futuras? -> A: Não. O app permite avançar somente até hoje; na data de hoje, a ação de próximo dia deve ficar desabilitada.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegar consumo por dia (Priority: P1)

Como usuário, quero visualizar e navegar entre datas para acompanhar meu consumo diário de calorias sem confusão.

**Why this priority**: o valor principal do app é o acompanhamento diário; sem navegação por data o histórico fica limitado e a leitura do consumo perde utilidade.

**Independent Test**: pode ser testado isoladamente ao abrir a Home, verificar data atual, navegar para dia anterior, dia seguinte e voltar para hoje, conferindo mudança de lista e total do dia.

**Acceptance Scenarios**:

1. **Given** o app foi aberto, **When** a Home é exibida, **Then** a data selecionada é o dia atual.
2. **Given** a Home com data selecionada, **When** o usuário toca em "dia anterior", **Then** a data muda para o dia anterior e a tela reflete os dados desse dia.
3. **Given** a Home em uma data diferente de hoje, **When** o usuário toca em "hoje", **Then** a data selecionada volta para o dia atual.
4. **Given** a Home está no dia atual, **When** o usuário tenta avançar para o próximo dia, **Then** a data permanece no dia atual e a ação de avançar está desabilitada.

---

### User Story 2 - Remover refeição com confirmação (Priority: P1)

Como usuário, quero remover uma refeição de um dia específico com confirmação para evitar exclusões acidentais e manter meu total diário correto.

**Why this priority**: remover registros incorretos é essencial para confiabilidade do acompanhamento calórico.

**Independent Test**: pode ser testado isoladamente adicionando refeições em um dia, removendo uma delas com confirmação e verificando atualização de lista e total.

**Acceptance Scenarios**:

1. **Given** há refeições no dia selecionado, **When** o usuário solicita remover uma refeição e confirma, **Then** a refeição sai da lista desse dia.
2. **Given** uma refeição removida no dia selecionado, **When** a remoção é concluída, **Then** o total de calorias do dia selecionado é recalculado.
3. **Given** existem refeições em outros dias, **When** uma refeição de um dia é removida, **Then** os dados dos demais dias permanecem inalterados.

---

### User Story 3 - Estado vazio por data (Priority: P2)

Como usuário, quero ver um estado vazio específico para a data selecionada quando não houver refeições naquele dia, para entender claramente que não existem registros para aquela data.

**Why this priority**: melhora clareza e evita interpretação errada de erro ou carregamento.

**Independent Test**: pode ser testado isoladamente navegando para uma data sem refeições e validando a mensagem específica por data.

**Acceptance Scenarios**:

1. **Given** uma data sem refeições, **When** a Home carrega essa data, **Then** a lista mostra estado vazio específico para aquela data.

---

### Edge Cases

- Navegação para datas com nenhuma refeição deve sempre mostrar total `0` e estado vazio específico da data.
- Remoção cancelada pelo usuário não deve alterar lista nem total.
- Mudança rápida entre datas não deve misturar refeições de dias diferentes na mesma visualização.
- Remoção em data diferente de hoje deve atualizar apenas o total daquela data.
- Na data atual, ação de avançar dia deve permanecer desabilitada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A Home MUST exibir de forma clara a data atualmente selecionada.
- **FR-002**: Ao abrir o app, a data selecionada MUST ser o dia atual.
- **FR-003**: Toda refeição adicionada MUST ser vinculada à data selecionada no momento da inclusão; ao salvar, o `timestamp` MUST usar a data selecionada combinada com a hora local atual do dispositivo.
- **FR-004**: O total de calorias exibido MUST considerar apenas refeições da data selecionada.
- **FR-005**: A lista de refeições MUST exibir apenas refeições da data selecionada.
- **FR-006**: O usuário MUST conseguir navegar para o dia anterior.
- **FR-007**: O usuário MUST conseguir navegar para o dia seguinte apenas quando a data selecionada for anterior ao dia atual.
- **FR-008**: O usuário MUST conseguir retornar para o dia atual com ação explícita.
- **FR-009**: Antes da remoção definitiva, o sistema MUST solicitar confirmação simples do usuário.
- **FR-010**: Ao confirmar remoção, a refeição MUST ser removida da lista e suas calorias subtraídas do total da data selecionada.
- **FR-011**: A remoção de refeição MUST afetar somente os dados da data da refeição removida.
- **FR-012**: Quando não houver refeições na data selecionada, a Home MUST exibir estado vazio específico para aquela data.
- **FR-013**: A experiência de uso MUST permanecer simples, leve e funcional, sem introduzir fluxos complexos fora do escopo.
- **FR-014**: Na data atual, o controle de navegar para próximo dia MUST ficar desabilitado.

### Key Entities *(include if feature involves data)*

- **DiaSelecionado**: representa a data ativa no contexto da Home, usada para filtrar lista e total diário.
- **Refeição**: registro de consumo com descrição, calorias, origem e data/hora; cada refeição pertence a um dia específico.
- **ResumoDiario**: agregação do total de calorias e quantidade de refeições para uma data selecionada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das aberturas do app, a Home exibe o dia atual como data selecionada inicial.
- **SC-002**: Em testes de navegação diária, 100% das transições válidas (dia anterior, dia seguinte até hoje, voltar para hoje) atualizam corretamente data, lista e total em até 1 segundo percebido.
- **SC-003**: Em testes de remoção com confirmação, 100% das refeições removidas deixam de aparecer na lista e o total diário é recalculado corretamente para a data selecionada.
- **SC-004**: Em testes com múltiplas datas, 100% das remoções em uma data não alteram listas e totais de outras datas.
- **SC-005**: Para datas sem refeições, a Home exibe estado vazio específico em 100% dos cenários testados.

## Assumptions

- O app continuará funcionando sem backend e sem sincronização em nuvem nesta feature.
- O armazenamento local atual já permite associar cada refeição a uma data/hora de criação.
- Ao salvar refeição em data diferente de hoje, o sistema ajustará o `timestamp` para a data selecionada com hora local atual para preservar consistência diária.
- O volume de dados no MVP é baixo o suficiente para filtragem por data sem necessidade de otimização avançada.
- Não haverá calendário mensal completo nesta fase; a navegação será apenas por ações de avançar, voltar e retornar para hoje.
- Edição de refeição permanece fora do escopo desta feature.
