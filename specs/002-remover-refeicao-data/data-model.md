# Data Model: Remover refeição e navegar por data

**Generated**: 2026-06-15 | **For**: Feature 002

## Entities

### ResumoDiario (Agregação)

Representa o estado resumido da tela Home para uma data selecionada.

```
Entity: ResumoDiario
  - dataSelecionada (DateTime): data ativa no contexto da Home
  - totalCalorias (int): soma de calorias das refeições do dia
  - quantidadeRefeicoes (int): contagem de refeições do dia
  - refeicoes (List<Meal>): lista filtrada de refeições da data
  - estaVazio (bool): true se quantidadeRefeicoes == 0
```

**Validações**:
- `dataSelecionada` nunca pode ser data futura (sempre <= hoje).
- `totalCalorias` calculado em tempo real a partir de `refeicoes`.
- `estaVazio` é sempre `refeicoes.length == 0`.

**State Transitions**:
- Quando usuário navega para nova data, `ResumoDiario` é recalculado.
- Quando refeição é adicionada ou removida, `totalCalorias` e `quantidadeRefeicoes` são atualizados.
- Quando removida a última refeição da data, `estaVazio` torna-se true.

---

### Meal (Existente, Extensão)

Modelo já definido em feature 001; esta feature adiciona validação de contexto:

```
Entity: Meal (existente)
  - id (String): UUID único
  - descricao (String): texto da refeição
  - calorias (int): estimativa calórica
  - timestamp (DateTime): data e hora de criação (AJUSTADO para dataSelecionada)
  - origem (MealOrigem): texto | audio
  - aiConfidence? (double): confiança da estimativa, 0.0-1.0
  - nota? (String): observação adicional
  
Novo na feature 002:
  - timestamp MUST ser ajustado para (dataSelecionada + hora local)
    quando refeição for adicionada em data diferente de hoje
```

**Validações (Feature 002)**:
- Quando adicionada em `dataSelecionada != hoje`, o `timestamp` é forçadamente ajustado.
- Comparação de data para filtragem usa `DateTime(year, month, day)` ignorando hora.
- Remoção de refeição remove apenas o item específico; não afeta outras datas.

---

### NavigationState (Novo)

Encapsula o estado de navegação de datas.

```
Entity: NavigationState
  - dataSelecionada (DateTime): data ativa (somente dia, mês, ano; sem hora)
  - podeVoltar (bool): sempre true (pode navegar para qualquer dia passado)
  - podeAvancar (bool): true se dataSelecionada < hoje
  - eHoje (bool): true se dataSelecionada == hoje
```

**Validações**:
- `dataSelecionada` nunca é data futura.
- `podeVoltar` sempre true (sem limite inferior de data).
- `podeAvancar` computed a partir de comparação com `DateTime.now()`.
- `eHoje` usado para desabilitar UI do botão "próximo dia".

---

## Relacionamentos

```
ResumoDiario
  └─ dataSelecionada (DateTime)
  └─ refeicoes (List<Meal>)
       ├─ Meal[0]
       │  └─ timestamp.toLocalDate() == dataSelecionada
       ├─ Meal[1]
       │  └─ timestamp.toLocalDate() == dataSelecionada
       └─ ...

NavigationState
  └─ dataSelecionada (DateTime)
       └─ referencia mesma data em ResumoDiario
```

---

## State Transitions (Diagramas)

### Navegação de Datas

```
Estado Inicial: [dataSelecionada = Hoje]

Usuário pressiona "< Anterior":
  → dataSelecionada = Hoje - 1 dia
  → ResumoDiario recalculado (filtra Meals com timestamp naquele dia)
  → podeAvancar = true (pode avançar até Hoje)
  → UI renderizada com novo total e lista

Usuário pressiona "> Próximo" (quando dataSelecionada < Hoje):
  → dataSelecionada = dataSelecionada + 1 dia
  → Se dataSelecionada + 1 == Hoje:
     → podeAvancar desabilitado na UI
  → ResumoDiario recalculado

Usuário pressiona "Hoje":
  → dataSelecionada = Hoje
  → podeAvancar = false (desabilitado)
  → podeVoltar = true (pode voltar para dias passados)
  → ResumoDiario renderizado com refeições de hoje
```

### Remoção de Refeição

```
Estado: dataSelecionada = 15 de junho, lista tem 3 refeições

Usuário long-press em Refeição #2:
  → Dialog exibido: "Tem certeza que quer remover?"

Se confirma:
  → Refeição #2 removida do repositório
  → totalCalorias = totalCalorias - calorias_refeicao_2
  → Apenas data (15 de junho) é afetada
  → Se essa era a última refeição, estaVazio = true

Se cancela:
  → Dialog fecha, lista permanece inalterada
```

---

## Validação & Constraints

| Validação | Tipo | Regra |
|-----------|------|-------|
| Data Futura | Rejeição | `dataSelecionada` nunca pode ser > Hoje |
| Timestamp Ajuste | Transformação | Ao salvar em data != hoje, ajustar para (dataSelecionada + hora local) |
| Múltiplos Dias | Isolamento | Remoção em um dia nunca afeta outro |
| Estado Vazio | Display | Se `refeicoes.isEmpty()`, mostrar mensagem específica da data |
| Botão Próximo | Desabilitar | `podeAvancar` fica false quando `dataSelecionada == Hoje` |

---

**Status**: COMPLETE — modelo de dados e transições definidas.
