# Data Model: Design System e Layout Material 3

**Generated**: 2026-06-16 | **For**: Feature 003

## Entidades

### Meal (extensão)

Representa refeição exibida na Home e salva no repositório local.

- `id` (String)
- `descricao` (String)
- `calorias` (int)
- `timestamp` (DateTime)
- `origem` (MealOrigem)
- `aiConfidence` (double?)
- `nota` (String?)
- `iconKey` (String) **novo**

**Validações**:
- `descricao` não vazia.
- `calorias >= 0`.
- `iconKey` deve estar no conjunto suportado; se inválido/ausente, persistir `default`.

---

### AiEstimate (extensão)

Representa retorno de estimativa da IA para revisão antes do salvamento.

- `descricaoInterpretada` (String)
- `calorias` (int)
- `observacao` (String?)
- `confidence` (double)
- `iconKey` (String) **novo**

**Validações**:
- `calorias >= 0`.
- `confidence` entre `0.0` e `1.0`.
- `iconKey` normalizado para conjunto suportado com fallback `default`.
- `observacao` pode conter premissas de porção, por exemplo: "quantidade não informada; assumido 100g".

---

### DesignTokens (novo artefato lógico)

Conjunto de tokens para padronização visual.

- `color.primary`, `color.surface`, `color.error`, etc.
- `typography.displayLarge`, `titleLarge`, `bodyLarge`, `labelLarge`
- `spacing.xs/sm/md/lg/xl`
- `radius.sm/md/lg`
- `elevation.level1/level2`

**Regra**:
- Componentes de Home/Add/Review/Dialogs devem usar tokens, sem valores mágicos repetidos.

## Enumerações e Conjuntos

### IconKey suportadas

- `breakfast`
- `lunch`
- `dinner`
- `snack`
- `drink`
- `dessert`
- `default`

## Regras de Estado

1. **Revisão de estimativa**:
   - Exibe `descricaoInterpretada`, `calorias`, `confidence`, `observacao` e pré-visualização de ícone.
2. **Salvamento**:
   - `Meal.iconKey` recebe `AiEstimate.iconKey` normalizado.
3. **Lista Home**:
   - Renderiza ícone por `iconKey` da refeição.
4. **Fallback**:
   - Se retorno da IA não trouxer `iconKey` válido, usar `default`.

## Transições relevantes

- Entrada texto/áudio -> `AiEstimate` com `iconKey` e `observacao` -> revisão -> confirmação -> `Meal` persistida com `iconKey` normalizado.
