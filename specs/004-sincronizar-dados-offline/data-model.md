# Modelo de Dados: Sincronização Online e Offline

## Convenções

- IDs de entidades e operações são UUIDs estáveis.
- Datas de sincronização usam ISO 8601 em UTC. O offset recebido pode ser preservado para auditoria, mas comparações usam o instante normalizado.
- `mealAt` representa quando a refeição ocorreu; `modifiedAt` representa quando seu conteúdo foi alterado. Eles nunca são intercambiáveis.
- A identidade remota efetiva é `(userId, entityType, entityId)`.
- Conteúdo de domínio e DTOs remotos permanecem separados.

## Refeição (`Meal`)

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID/string | Estável desde a criação |
| `description` | texto | Obrigatório, 2–1.000 caracteres |
| `originalDescription` | texto opcional | Máximo 1.000 caracteres |
| `calories` | inteiro | 0–20.000 |
| `mealAt` | instante | Data/hora da refeição |
| `origin` | enum | `text` ou `audio` |
| `aiConfidence` | decimal opcional | 0–1 |
| `note` | texto opcional | Máximo 2.000 caracteres |
| `iconKey` | texto | Chave suportada ou `default` |
| `proteinGrams` | inteiro | 0–5.000 |
| `carbohydrateGrams` | inteiro | 0–5.000 |
| `fatGrams` | inteiro | 0–5.000 |
| `modifiedAt` | instante | Gerado no dispositivo a cada mutação |
| `deletedAt` | instante opcional | Tombstone; quando preenchido, não aparece na UI |
| `ownerUserId` | string opcional | `null` no modo anônimo; associado após login confirmado |

### Invariantes

- Uma remoção atualiza `modifiedAt` e `deletedAt` no mesmo instante.
- A refeição permanece no armazenamento enquanto o tombstone for necessário para propagação.
- Dados anônimos só recebem `ownerUserId` ao serem aceitos no bootstrap da conta.
- A versão remota vence conflitos do bootstrap; depois vence o maior `modifiedAt`.

## Meta nutricional (`NutritionGoal`)

Nesta versão há uma única meta sincronizável: meta calórica diária.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | string | Valor canônico `daily-calorie` por usuário |
| `type` | enum | `dailyCalories` |
| `targetValue` | inteiro | 800–6.000 |
| `unit` | enum | `kcalPerDay` |
| `effectiveFrom` | data local | Início da vigência |
| `effectiveUntil` | data local opcional | Deve ser posterior ou igual ao início |
| `modifiedAt` | instante | Momento da alteração no dispositivo |
| `deletedAt` | instante opcional | Permite propagar remoção/reset |
| `ownerUserId` | string opcional | Mesmo ciclo de associação da refeição |

## Operação pendente (`SyncOperation`)

| Campo | Tipo | Regras |
|---|---|---|
| `operationId` | UUID | Chave idempotente imutável |
| `entityType` | enum | `meal` ou `nutritionGoal` |
| `entityId` | string | ID estável da entidade |
| `operation` | enum | `upsert` ou `delete` |
| `occurredAt` | instante | Igual ao `modifiedAt` da mutação |
| `ownerUserId` | string opcional | Definido ao associar dados anônimos à conta |
| `status` | enum | `pending`, `sending`, `acknowledged`, `failed` |
| `attemptCount` | inteiro | Inicia em 0; nunca negativo |
| `lastAttemptAt` | instante opcional | Diagnóstico/retry |
| `lastErrorCode` | texto opcional | Código não sensível |

### Transições

```text
pending → sending → acknowledged
    ↑        │
    └─ failed┘
```

- Reiniciar o app converte `sending` sem confirmação em `pending`.
- `PREMIUM_REQUIRED` pausa operações sem removê-las.
- Uma operação reconhecida pode ser removida da outbox após a entidade canônica ser aplicada.

## Estado de sincronização (`SyncCheckpoint`)

| Campo | Tipo | Regras |
|---|---|---|
| `ownerUserId` | string | Um checkpoint por conta no dispositivo |
| `deviceId` | UUID | Estável por instalação |
| `cursor` | string opcional | Opaco, emitido pelo BFF |
| `bootstrapState` | enum | `notStarted`, `running`, `completed` |
| `lastSuccessAt` | instante opcional | Último ciclo concluído |
| `lastErrorCode` | texto opcional | Sem payload pessoal |
| `cleanupPending` | booleano | Bloqueia exposição de dados até concluir limpeza |

## Mudança remota (`RemoteChange`)

| Campo | Tipo | Regras |
|---|---|---|
| `sequence` | inteiro longo | Monotônico por feed |
| `entityType` | enum | `meal` ou `nutritionGoal` |
| `entityId` | string | Identidade dentro da conta |
| `operation` | enum | `upsert` ou `delete` |
| `modifiedAt` | instante | Originado no dispositivo vencedor |
| `payload` | objeto opcional | Obrigatório para `upsert`, ausente para `delete` |

## Registro idempotente remoto (`ProcessedSyncOperation`)

| Campo | Tipo | Regras |
|---|---|---|
| `userId` | string | Parte da chave |
| `operationId` | UUID | Parte da chave única |
| `requestDigest` | hash | Detecta reutilização indevida com payload diferente |
| `resultStatus` | enum | `applied`, `ignored`, `rejected` |
| `processedAt` | instante | Horário do BFF |
| `resultSnapshot` | objeto | Resultado canônico repetível |

## Relacionamentos

- Uma conta possui muitas refeições, uma meta calórica e muitas operações processadas.
- Uma instalação possui uma outbox e um checkpoint por conta ativa.
- Cada mutação aceita gera uma mudança remota sequenciada.
- Tombstones pertencem à mesma identidade da entidade removida.

## Regras de merge

1. **Bootstrap**: para ID presente nos dois lados, remoto vence; IDs exclusivos são preservados.
2. **Pós-bootstrap**: maior `modifiedAt` vence.
3. **Empate exato**: maior `operationId` lexical vence para convergência determinística.
4. **Delete versus update**: ambas são mutações; vence a de maior `modifiedAt`.
5. **Operação antiga**: retorna `ignored` com a versão canônica, sem novo efeito.
6. **Mesmo `operationId`, payload diferente**: rejeitar como conflito de idempotência.

## Limpeza no logout

A limpeza transacional remove refeições e metas da conta ativa, outbox, checkpoint, token e sessão. Preferências exclusivamente locais podem permanecer. `cleanupPending` é persistido antes da limpeza e removido apenas ao final; no startup, sua presença exige finalizar a limpeza antes de montar a UI autenticada ou anônima.
