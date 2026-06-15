# Quickstart: Remover refeição e navegar por data

**Generated**: 2026-06-15 | **For**: Feature 002 | **Type**: Validation Guide

## Prerequisites

- Flutter 3.12+, Dart 3.x
- Android emulator running (pixel_33_api or similar)
- Feature 001 implemented and working (Home exibindo refeições)
- `intl` package added to `pubspec.yaml` (for date formatting)

## Setup

```bash
cd app
flutter pub get
flutter run
```

**Expected**: App boots on emulator, HomePage visible with today's date and meals.

---

## Scenario 1: Date Navigation (Forward & Backward)

### Objective
Validar que navegação entre datas funciona: voltar dia, avançar dia (até hoje), voltar para hoje.

### Steps

1. **Abrir app** → Home visível
   - Verificar: header exibe data de hoje (ex: "seg, 15 de junho")
   - Verificar: botões de navegação: "< Anterior", "Hoje", "> Próximo"

2. **Pressionar "< Anterior"**
   - Verificar: data muda para dia anterior (ex: "dom, 14 de junho")
   - Verificar: lista atualiza para refeições de 14 de junho
   - Verificar: botão "> Próximo" habilitado

3. **Pressionar "< Anterior" mais 2 vezes**
   - Verificar: data continua recuando (ex: "sex, 12 de junho")
   - Verificar: sem limite inferior (pode voltar meses para trás)

4. **Pressionar "> Próximo"**
   - Verificar: data avança (ex: "sáb, 13 de junho")
   - Verificar: lista atualiza

5. **Pressionar "> Próximo" até atingir hoje**
   - Verificar: ao chegar em hoje (ex: "seg, 15 de junho"), botão "> Próximo" fica **desabilitado**
   - Verificar: tentar pressionar novamente não faz nada

6. **Pressionar "Hoje" de qualquer data anterior**
   - Verificar: data volta imediatamente para hoje
   - Verificar: lista exibe refeições de hoje

### Success Criteria
- ✓ Navegação anterior sem limite
- ✓ Navegação próxima bloqueada em hoje
- ✓ Botão "Próximo" desabilitado quando em hoje
- ✓ Lista e total atualizam conforme data muda
- ✓ Transição entre datas < 1 segundo percebido

---

## Scenario 2: Multi-Day Data Isolation

### Objective
Validar que refeições de diferentes datas permanecem isoladas.

### Setup
1. Adicionar 2 refeições **em 14 de junho** (dia anterior a hoje)
2. Adicionar 3 refeições **em 15 de junho** (hoje)

### Steps

1. **Abrir Home em hoje (15 de junho)**
   - Verificar: total = soma das 3 refeições de hoje
   - Verificar: lista exibe apenas 3 refeições

2. **Navegar para 14 de junho**
   - Verificar: total = soma das 2 refeições de 14 de junho
   - Verificar: lista exibe apenas 2 refeições (diferentes das de hoje)

3. **Voltar para hoje (15 de junho)**
   - Verificar: total = volta aos valores de hoje (3 refeições)
   - Verificar: lista exibe as 3 refeições de hoje (não misturadas com 14 de junho)

### Success Criteria
- ✓ Filtro de data funciona corretamente
- ✓ Totais calculados por data (não global)
- ✓ Navegação não mistura refeições de diferentes datas

---

## Scenario 3: Remove Meal with Confirmation

### Objective
Validar que remoção de refeição exige confirmação e afeta apenas a data correta.

### Setup
- Home em hoje com >= 2 refeições

### Steps

1. **Long-press em uma refeição**
   - Verificar: dialog exibido: "Remover refeição?"
   - Verificar: opções: "Cancelar" e "Remover"

2. **Pressionar "Cancelar"**
   - Verificar: dialog fecha
   - Verificar: lista permanece inalterada
   - Verificar: total permanece igual

3. **Long-press em outra refeição**
   - Verificar: dialog exibido novamente

4. **Pressionar "Remover"**
   - Verificar: dialog fecha
   - Verificar: refeição sai da lista
   - Verificar: total reduz (subtraindo calorias da refeição removida)

5. **Se removida última refeição do dia**
   - Verificar: lista exibe estado vazio para aquela data
   - Verificar: total = 0

### Success Criteria
- ✓ Confirmação dialog exibido antes de remover
- ✓ Cancelamento preserva lista
- ✓ Remoção confirmada remove item e atualiza total
- ✓ Última refeição removida exibe estado vazio

---

## Scenario 4: Timestamp Adjustment (Optional Visual Check)

### Objective
Validar que refeição adicionada em data não-hoje é salva com timestamp correto.

### Steps

1. **Navegar para 14 de junho (dia anterior)**

2. **Adicionar refeição (ex: "Arroz com frango")**
   - Preencher descrição
   - Estimar com IA ou inserir calorias manualmente
   - Confirmar

3. **Verificar**: Refeição aparece na lista de 14 de junho
   - (Verificação interna: em `_meals`, `timestamp.year/month/day` == 14 de junho)

4. **Navegar para 15 de junho (hoje)**
   - Verificar: refeição não aparece na lista de hoje

5. **Navegar de volta para 14 de junho**
   - Verificar: refeição continua lá

### Success Criteria
- ✓ Refeição adicionada em data não-hoje fica vinculada a essa data
- ✓ Timestamp ajustado para data selecionada + hora local
- ✓ Filtragem funciona corretamente entre datas

---

## Scenario 5: Empty State by Date

### Objective
Validar que estado vazio exibe mensagem específica por data.

### Steps

1. **Navegar para uma data sem refeições** (ex: 10 de junho, dia aleatório do passado)

2. **Verificar**: Tela exibe:
   - Ícone de prato vazio (ou similar)
   - Mensagem: "Nenhuma refeição em 10 de junho"

3. **Navegar para outra data vazia**

4. **Verificar**: Mensagem atualiza (ex: "Nenhuma refeição em 9 de junho")

### Success Criteria
- ✓ Estado vazio exibido quando data não tiver refeições
- ✓ Mensagem é contextualizada à data específica
- ✓ Diferente de erro ou carregamento; clareza visual

---

## Scenarios Covered by Data-Model & Contracts

For detailed behavioral specifications and edge cases, see:
- [data-model.md](./data-model.md) — Validações, transições de estado
- [contracts/date-navigation.md](./contracts/date-navigation.md) — Interface de navegação, tabelas de comportamento
- [contracts/meal-removal.md](./contracts/meal-removal.md) — Interface de remoção, tratamento de erros

---

## Next Steps

1. **Before running quickstart**: Implementar todas as tasks de feature 002 (geradas em Phase 2).
2. **During implementation**: Executar cenários acima para validação incremental.
3. **Before final sign-off**: Executar todos os 5 cenários em sequência no emulator.

**Status**: READY FOR TESTING — Cenários validáveis e mensuráveis.
