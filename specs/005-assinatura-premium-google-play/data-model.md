# Modelo de Dados: Assinatura Premium

## Assinatura

Representa o direito de uso Premium validado pelo BFF para uma conta Nutrity.

| Campo | Regra |
|---|---|
| `id` | Identificador interno imutável. |
| `userId` | Obrigatório; referencia a conta autenticada. |
| `provider` | Obrigatório; nesta feature, `GOOGLE_PLAY`. |
| `purchaseToken` | Obrigatório, único globalmente e armazenado protegido; usado para idempotência. |
| `productId` | Obrigatório; produto retornado pela Google Play. |
| `basePlanId` | Obrigatório quando fornecido pela Google Play. |
| `offerId` | Opcional; identifica a oferta aplicada. |
| `status` | Um dos estados canônicos definidos abaixo. |
| `startedAt` | Data/hora UTC do início. |
| `expiresAt` | Data/hora UTC de fim de acesso, quando aplicável. |
| `nextBillingAt` | Data/hora UTC da próxima cobrança, quando disponível. |
| `autoRenewEnabled` | Situação atual de renovação automática. |
| `accountBindingHash` | Hash do identificador ofuscado da conta, usado para conferir o vínculo. |
| `linkedPurchaseToken` | Opcional; token anterior em reinício ou troca de plano. |
| `lastValidatedAt` | Data/hora UTC da última confirmação na Google Play. |
| `createdAt` / `updatedAt` | Auditoria temporal em UTC. |

**Restrições**:
- `purchaseToken` é único e só pode pertencer a um `userId`.
- Uma conta pode ter histórico de várias assinaturas, mas apenas uma assinatura com acesso válido por vez.
- Toda atualização de status deve resultar de resposta autoritativa da Google Play, exceto marcação técnica de processamento pendente.

## Estado da Assinatura

| Estado canônico | Acesso Premium | Origem esperada |
|---|---:|---|
| `PENDING` | Não | Compra iniciada/aguardando confirmação. |
| `ACTIVE` | Sim | Assinatura ativa. |
| `TRIAL` | Sim | Período de teste ativo. |
| `GRACE_PERIOD` | Sim | Falha temporária de pagamento com acesso preservado. |
| `CANCELED_ACTIVE` | Sim | Renovação cancelada, mas período pago vigente. |
| `SUSPENDED` | Não | Conta em retenção, pausa ou suspensão. |
| `EXPIRED` | Não | Período encerrado. |
| `REFUNDED` | Não | Reembolso confirmado. |
| `REVOKED` | Não | Revogação confirmada. |

### Transições

```text
PENDING -> ACTIVE | TRIAL | EXPIRED
ACTIVE | TRIAL -> GRACE_PERIOD | CANCELED_ACTIVE | SUSPENDED | REFUNDED | REVOKED | EXPIRED
GRACE_PERIOD -> ACTIVE | CANCELED_ACTIVE | SUSPENDED | EXPIRED
SUSPENDED -> ACTIVE | EXPIRED | REVOKED
CANCELED_ACTIVE -> ACTIVE | EXPIRED | REVOKED
EXPIRED | REFUNDED | REVOKED -> ACTIVE  (somente nova compra/reinício validado)
```

Uma transição recebida por notificação nunca é aplicada sem consulta do estado atual na Google Play.

## Evento de Auditoria de Assinatura

Registra uma tentativa de validação, reconhecimento, atualização de status, RTDN ou reconciliação.

| Campo | Regra |
|---|---|
| `id` | Identificador interno. |
| `subscriptionId` | Opcional para tentativa inválida; obrigatório quando houver assinatura conhecida. |
| `eventType` | `VALIDATION`, `ACKNOWLEDGEMENT`, `RTDN`, `RECONCILIATION`, `RESTORE` ou `STATUS_CHANGE`. |
| `source` | `APP`, `GOOGLE_PLAY` ou `SCHEDULED_JOB`. |
| `correlationId` | Obrigatório para rastreabilidade. |
| `outcome` | `SUCCESS`, `REJECTED`, `RETRYABLE_FAILURE` ou `FAILED`. |
| `previousStatus` / `newStatus` | Obrigatórios em mudança de estado. |
| `providerReferenceMasked` | Referência mascarada; nunca o token integral. |
| `occurredAt` | Data/hora UTC. |

## Cursor de Reconciliação

Mantém o progresso da busca periódica de compras anuladas e evita reprocessamento desnecessário.

| Campo | Regra |
|---|---|
| `provider` | Único por provedor. |
| `lastSuccessfulAt` | Último ponto UTC confirmado. |
| `continuationToken` | Opcional; usado durante paginação. |
| `updatedAt` | Data/hora UTC. |

## Relações

```text
Usuário 1 --- N Assinatura
Assinatura 1 --- N Evento de Auditoria
Provedor 1 --- 1 Cursor de Reconciliação
```

O perfil do usuário pode manter uma projeção do acesso efetivo para autorização rápida, mas essa projeção é derivada da assinatura validada e não substitui seu histórico.
