# Contrato HTTP: Assinaturas Premium

## Convenções

- Todas as datas usam ISO 8601 em UTC.
- Endpoints autenticados exigem `Authorization: Bearer <token>`.
- O BFF deriva o usuário autenticado do token; o cliente não informa `userId`.
- Tokens de compra nunca aparecem em resposta, log ou mensagem de erro integralmente.
- Erros usam o formato já adotado pelo BFF, com `code`, `message` e `correlationId`.

## `GET /subscriptions/catalog`

Retorna a projeção de planos/ofertas disponível para apresentação no aplicativo.

**Autorização**: Não exige autenticação para consultar; a compra exige autenticação.

**Resposta 200**

```json
{
  "offers": [
    {
      "productId": "premium_monthly",
      "basePlanId": "monthly",
      "offerId": null,
      "title": "Premium mensal",
      "formattedPrice": "R$ 14,90",
      "billingPeriod": "P1M",
      "eligible": true
    }
  ]
}
```

## `POST /subscriptions/validate`

Associa e valida uma compra concluída. A operação é idempotente por `purchaseToken`.

**Autorização**: Obrigatória.

**Requisição**

```json
{
  "purchaseToken": "token recebido da Google Play",
  "productId": "premium_monthly",
  "accountBinding": "identificador-ofuscado-da-conta"
}
```

**Resposta 200**

```json
{
  "plan": "PREMIUM",
  "subscription": {
    "status": "ACTIVE",
    "productId": "premium_monthly",
    "basePlanId": "monthly",
    "autoRenewEnabled": true,
    "expiresAt": "2026-08-28T00:00:00Z",
    "nextBillingAt": "2026-08-28T00:00:00Z"
  }
}
```

**Erros**

| Código | Situação |
|---|---|
| `400 INVALID_PURCHASE` | Token, produto ou vínculo incompatível com a resposta da Google Play. |
| `401 UNAUTHORIZED` | Token de usuário ausente ou inválido. |
| `409 PURCHASE_ALREADY_BOUND` | Compra já pertence a outro usuário. |
| `409 PURCHASE_PENDING` | Compra ainda não está concluída. |
| `502 PROVIDER_UNAVAILABLE` | Google Play indisponível; cliente pode tentar novamente. |

## `GET /subscriptions/me`

Retorna o plano efetivo calculado pelo BFF e o resumo seguro da assinatura.

**Autorização**: Obrigatória.

**Resposta 200**

```json
{
  "plan": "PREMIUM",
  "subscription": {
    "status": "CANCELED_ACTIVE",
    "productId": "premium_monthly",
    "basePlanId": "monthly",
    "autoRenewEnabled": false,
    "expiresAt": "2026-08-28T00:00:00Z",
    "nextBillingAt": null
  }
}
```

Para plano Free, `plan` é `FREE` e `subscription` é `null`.

## `POST /subscriptions/restore`

Recebe compras atuais recuperadas pelo aplicativo e aplica a mesma validação idempotente de `POST /subscriptions/validate`.

**Autorização**: Obrigatória.

**Requisição**

```json
{
  "purchases": [
    {
      "purchaseToken": "token recebido da Google Play",
      "productId": "premium_monthly",
      "accountBinding": "identificador-ofuscado-da-conta"
    }
  ]
}
```

**Resposta 200**: Mesmo formato de `GET /subscriptions/me`.

## Proteção de funcionalidades Premium

Todo endpoint Premium do BFF consulta o entitlement efetivo no servidor. Cache do aplicativo é apenas visual e não substitui essa autorização.
