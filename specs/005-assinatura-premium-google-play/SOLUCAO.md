# Feature 005 — Assinatura Premium e Integração com Google Play Billing

> **Escopo:** Android · Google Play Billing · BFF Spring Boot  
> **Idioma dos artefatos:** Português do Brasil

---

## Índice

1. [Visão geral da solução](#1-visão-geral-da-solução)
2. [Fluxo completo de contratação](#2-fluxo-completo-de-contratação)
3. [Camada Flutter (app)](#3-camada-flutter-app)
   - 3.1 [Modelos de domínio](#31-modelos-de-domínio)
   - 3.2 [Abstrações de porta](#32-abstrações-de-porta)
   - 3.3 [Adaptadores de infraestrutura](#33-adaptadores-de-infraestrutura)
   - 3.4 [SubscriptionService](#34-subscriptionservice)
   - 3.5 [Estados de compra](#35-estados-de-compra)
   - 3.6 [Telas](#36-telas)
4. [Camada BFF (Spring Boot)](#4-camada-bff-spring-boot)
   - 4.1 [Endpoints REST](#41-endpoints-rest)
   - 4.2 [Serviços de aplicação](#42-serviços-de-aplicação)
   - 4.3 [Entidades de domínio](#43-entidades-de-domínio)
   - 4.4 [Infraestrutura Google Play](#44-infraestrutura-google-play)
   - 4.5 [Renovação automática e reconciliação](#45-renovação-automática-e-reconciliação)
   - 4.6 [Segurança do token de compra](#46-segurança-do-token-de-compra)
   - 4.7 [Auditoria](#47-auditoria)
   - 4.8 [Configuração](#48-configuração)
5. [Modelo de dados](#5-modelo-de-dados)
6. [Estados da assinatura e máquina de transições](#6-estados-da-assinatura-e-máquina-de-transições)
7. [Segurança](#7-segurança)
8. [Credenciais e configuração Google — guia completo](#8-credenciais-e-configuração-google--guia-completo)
   - 8.1 [Visão geral: dois contextos, mesma conta Google](#81-visão-geral-dois-contextos-mesma-conta-google)
   - 8.2 [Login OAuth Google (Google Sign-In)](#82-login-oauth-google-google-sign-in)
   - 8.3 [Google Play Billing (pagamento e assinatura)](#83-google-play-billing-pagamento-e-assinatura)
   - 8.4 [Service Account (BFF ↔ Google Play Developer API)](#84-service-account-bff--google-play-developer-api)
   - 8.5 [RTDN via Cloud Pub/Sub](#85-rtdn-via-cloud-pubsub)
   - 8.6 [Resumo: onde cada credencial fica](#86-resumo-onde-cada-credencial-fica)
9. [Variáveis de ambiente](#9-variáveis-de-ambiente)
10. [Inicialização e checklist de deploy](#10-inicialização-e-checklist-de-deploy)

---

## 1. Visão geral da solução

O Nutrity possui dois planos:

| Plano   | Autenticação | Origem da verdade |
|---------|-------------|-------------------|
| Free    | Não         | Local (SQLite)    |
| Premium | Google OAuth| BFF               |

A feature 005 implementa o caminho **Free → Premium** inteiramente via Google Play Billing, sem nenhum dado de cartão trafegar pelo aplicativo. O BFF é a **única** fonte de verdade sobre se o usuário tem direito Premium.

### Princípio-chave: autenticação após pagamento

O usuário pode iniciar o fluxo sem estar autenticado. O pedido de login ao Google ocorre **durante** o fluxo de compra — logo antes de lançar a tela da Google Play — para que o `accountBinding` (vínculo de conta) seja gerado a partir do `userId` já conhecido pelo BFF. Isso garante que a compra não possa ser reutilizada por outra conta.

### Diagrama de contexto

```
┌─────────────────────┐    purchase token    ┌──────────────────────┐
│   App Flutter       │──────────────────────▶  BFF Spring Boot     │
│   (Android)         │◀──── JWT + summary ──│                      │
│                     │                       │  Google Play         │
│  in_app_purchase    │                       │  Developer API       │
│  (Google Play SDK)  │                       │  (validação server)  │
└─────────────────────┘                       └──────────────────────┘
         │                                              ▲
         │  UI nativa Google Play                       │ RTDN (Pub/Sub Push)
         ▼                                              │
  ┌─────────────────┐                        ┌─────────────────────┐
  │  Google Play    │────────────────────────▶  Google Cloud        │
  │  (pagamento)    │                         │  Pub/Sub            │
  └─────────────────┘                        └─────────────────────┘
```

---

## 2. Fluxo completo de contratação

```
Usuário                 App Flutter              BFF                  Google Play
   │                        │                     │                       │
   │── Seleciona plano ─────▶                     │                       │
   │                        │── Exibe ofertas ────│                       │
   │                        │◀── catalog ─────────│                       │
   │                        │                     │                       │
   │── Clica "Assinar" ─────▶                     │                       │
   │                        │── _ensureValidRemoteSession()               │
   │                        │   (solicita login Google se necessário)     │
   │                        │◀── JWT + userId ────│                       │
   │                        │                     │                       │
   │                        │── startPurchase(accountBinding = hash(userId))
   │                        │                     │                       │
   │◀── Tela Google Play ───│────────────────────────────────────────────▶│
   │── Confirma pagamento ──────────────────────────────────────────────▶ │
   │                        │◀────────────────────────── PurchaseDetails  │
   │                        │                     │                       │
   │                        │── POST /subscriptions/validate ────────────▶│
   │                        │       { purchaseToken, productId,           │
   │                        │         accountBinding }  + Bearer JWT      │
   │                        │                     │── GET subscriptions.v2.get
   │                        │                     │◀── SubscriptionPurchase
   │                        │                     │── Valida accountBinding
   │                        │                     │── Salva GooglePlaySubscription
   │                        │                     │── acknowledge()       │
   │                        │◀── { plan: PREMIUM, subscription: {...} } ──│
   │                        │                     │                       │
   │◀── Premium ativado ────│                     │                       │
```

---

## 3. Camada Flutter (app)

### 3.1 Modelos de domínio

**Arquivo:** [`app/lib/services/subscription/subscription_models.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/subscription_models.dart)

| Classe / enum | Responsabilidade |
|---------------|-----------------|
| `SubscriptionPlan` | `free` / `premium` — plano do usuário |
| `SubscriptionStatus` | 9 estados (ver §6); inclui `grantsEntitlement` |
| `SubscriptionOffer` | Uma oferta da Google Play: productId, basePlanId, offerId, preço formatado, período de cobrança |
| `PlayPurchase` | Resultado de uma compra: purchaseToken, productId, accountBinding |
| `SubscriptionDetails` | Detalhes de uma assinatura ativa retornada pelo BFF |
| `SubscriptionSummary` | Resposta canônica: plano + detalhes. `hasEntitlement` combina plano e status |

`SubscriptionStatus.grantsEntitlement` retorna `true` para: `active`, `trial`, `gracePeriod`, `canceledActive`.

### 3.2 Abstrações de porta

#### `PlayBillingAdapter`
**Arquivo:** [`app/lib/services/subscription/play_billing_adapter.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/play_billing_adapter.dart)

Porta de saída para o Google Play Billing. Operações:
- `initialize()` — inicia o listener do stream de compras
- `loadOffers()` → `List<SubscriptionOffer>`
- `startPurchase(offer, {accountBinding})` — lança a tela oficial Google Play
- `restorePurchases({accountBinding})` → `List<PlayPurchase>`
- `completePurchase(purchaseToken)` — confirma a entrega ao SDK
- `Stream<PlayPurchaseEvent> purchaseEvents` — eventos assíncronos de compra

#### `SubscriptionBffGateway`
**Arquivo:** [`app/lib/services/subscription/subscription_bff_gateway.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/subscription_bff_gateway.dart)

Porta de saída para o BFF. Operações:
- `fetchCatalog()` → `List<SubscriptionOffer>` (elegibilidade pelo BFF)
- `validatePurchase(purchase, {bearerToken})` → `SubscriptionSummary`
- `restorePurchases(purchases, {bearerToken})` → `SubscriptionSummary`
- `fetchSubscription({bearerToken})` → `SubscriptionSummary`

### 3.3 Adaptadores de infraestrutura

#### `GooglePlayBillingAdapter`
**Arquivo:** [`app/lib/services/subscription/google_play_billing_adapter.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/google_play_billing_adapter.dart)

Implementação concreta de `PlayBillingAdapter` usando o pacote `in_app_purchase` / `in_app_purchase_android`.

Detalhes de implementação relevantes:
- Usa `InAppPurchaseAndroidPlatformAddition.buyNonConsumable` com `SubscriptionAndroidPlatformAddition` para passar o `obfuscatedAccountId` (= `accountBinding`).
- `_handlePurchases` despacha eventos tipados (`pending`, `purchased`, `error`, `canceled`) para o stream.
- `restorePurchases` usa `InAppPurchase.restorePurchases()` e aguarda completude via `Completer`.
- IDs de produto configurados via `--dart-define=NUTRITY_GOOGLE_PLAY_PRODUCT_IDS`.

#### `GooglePlaySubscriptionManagement`
**Arquivo:** [`app/lib/services/subscription/google_play_subscription_management.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/google_play_subscription_management.dart)

Abre `https://play.google.com/store/account/subscriptions?package=...&sku=...` via `url_launcher` para o usuário gerenciar a assinatura diretamente na Google Play.

### 3.4 SubscriptionService

**Arquivo:** [`app/lib/services/subscription/subscription_service.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/subscription_service.dart)

É o **orquestrador central** da feature no Flutter. Extende `ChangeNotifier` (Provider). Responsabilidades:

| Método | Descrição |
|--------|-----------|
| `SubscriptionService.load(repository, ...)` | Factory assíncrona que carrega configurações persistidas |
| `initializePurchases()` | Conecta o stream do Billing, carrega ofertas, reconcilia subscription ao abrir |
| `refreshOffers()` | Busca ofertas no SDK e cruza com catálogo do BFF para filtrar elegíveis |
| `startPurchase(offer, {authenticate})` | Garante sessão autenticada → lança tela Google Play |
| `restorePurchases({authenticate})` | Restaura compras pelo SDK e valida no BFF |
| `refreshSubscription()` | Atualiza o resumo consultando o BFF |
| `authenticatePremiumWithGoogle(account)` | Autentica no BFF e aplica estado Premium |
| `restorePremiumWithGoogle(account)` | Fluxo de restauração via autenticação sem Billing |
| `selectFreePlan()` | Declara plano Free |
| `activatePremium(...)` | Ativa Premium localmente (callback pós-autenticação) |

**Proteção contra múltiplos fluxos:** `_purchaseState.blocksPurchase` bloqueia novas compras enquanto `isBusy` ou `pending`.

**`_accountBinding()`:** retorna `SHA-256("nutrity:" + userId)` — mesmo algoritmo usado pelo BFF para validar. Isso garante que o vínculo de compra seja verificável servidor-a-servidor sem expor o userId em texto claro para o Google Play.

**`_ensureValidRemoteSession()`:** antes de iniciar qualquer compra ou restauração, verifica se há token JWT válido. Se não houver, dispara o fluxo de autenticação Google (passado como callback `authenticate`).

### 3.5 Estados de compra

**Arquivo:** [`app/lib/services/subscription/subscription_purchase_state.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/subscription/subscription_purchase_state.dart)

```
idle ──▶ loadingOffers ──▶ ready
                            │
                            ▼
                       authenticating ──▶ launchingPurchase ──▶ validating
                            │                    │                   │
                            ▼                    ▼                   ▼
                         canceled            pending              success
                            │                    │                   │
                            └─────── recoverableFailure ◀────────────┘
                                          │
                                      unavailable
```

| Fase | `isBusy` | Bloqueia nova compra |
|------|----------|----------------------|
| `loadingOffers`, `authenticating`, `launchingPurchase`, `validating`, `restoring` | ✅ | ✅ |
| `pending` | ❌ | ✅ |
| `canceled`, `recoverableFailure`, `success`, `idle`, `ready` | ❌ | ❌ |

### 3.6 Telas

#### `PlanSelectionPage`
**Arquivo:** [`app/lib/features/onboarding/plan_selection_page.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/features/onboarding/plan_selection_page.dart)

Tela de apresentação de planos. Ações:
- **"Continuar grátis"** → `selectFreePlan()` → `HomeShellPage`
- **"Assinar Premium"** → navega para `PaywallPage` (sem restauração)
- **"Restaurar compra"** → navega para `PaywallPage` (com `restorePurchaseOnOpen: true`)

Exibe um `SnackBar` com mensagem quando a restauração não encontra assinatura ativa para o e-mail.

#### `PaywallPage`
**Arquivo:** [`app/lib/features/onboarding/paywall_page.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/features/onboarding/paywall_page.dart)

Tela de compra. Funcionalidades:
- Lista as `SubscriptionOffer` carregadas pelo `SubscriptionService`.
- Permite seleção de oferta e dispara `startPurchase`.
- Observa `purchaseState` via `context.watch<SubscriptionService>()` para feedback visual.
- Exibe estado de carregamento, erros com mensagem amigável e opção de nova tentativa.
- Navega para `HomeShellPage` ao receber `phase == success`.
- Oferece **preview estático** (`_previewOffers`) enquanto as ofertas reais carregam.

---

## 4. Camada BFF (Spring Boot)

### 4.1 Endpoints REST

**Arquivo:** [`SubscriptionController.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SubscriptionController.java)

| Método | Caminho | Auth | Descrição |
|--------|---------|------|-----------|
| `GET` | `/subscriptions/catalog` | Pública | Retorna ofertas elegíveis da Google Play |
| `POST` | `/subscriptions/validate` | JWT obrigatório | Valida compra e ativa Premium |
| `POST` | `/subscriptions/restore` | JWT obrigatório | Restaura compras existentes |
| `GET` | `/subscriptions/me` | JWT obrigatório | Retorna resumo da assinatura do usuário |

Header `X-Correlation-Id` opcional em todas as requisições — se não enviado, o BFF gera um UUID automático e o retorna na resposta.

**`POST /subscriptions/validate` — corpo:**
```json
{
  "purchaseToken": "<token obtido do Google Play SDK>",
  "productId": "premium_monthly",
  "accountBinding": "<SHA-256('nutrity:' + userId)>"
}
```

**`POST /subscriptions/restore` — corpo:**
```json
{
  "purchases": [
    { "purchaseToken": "...", "productId": "...", "accountBinding": "..." }
  ]
}
```

**Resposta comum (`SubscriptionSummaryResponse`):**
```json
{
  "plan": "PREMIUM",
  "subscription": {
    "status": "ACTIVE",
    "productId": "premium_monthly",
    "basePlanId": "monthly",
    "autoRenewEnabled": true,
    "expiresAt": "2025-12-31T23:59:59Z",
    "nextBillingAt": "2025-11-30T00:00:00Z"
  }
}
```

**`GET /subscriptions/catalog` — resposta:**
```json
{
  "offers": [
    {
      "productId": "premium_monthly",
      "basePlanId": "monthly",
      "offerId": null,
      "title": "Nutrity Premium Mensal",
      "formattedPrice": "R$ 14,90",
      "billingPeriod": "P1M",
      "eligible": true
    }
  ]
}
```

**Webhook RTDN:**
`POST /subscriptions/rtdn` — recebe notificações do Google Cloud Pub/Sub (ver §4.5).

### 4.2 Serviços de aplicação

#### `SubscriptionValidationService`
**Arquivo:** [`SubscriptionValidationService.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionValidationService.java)

Orquestra o fluxo de validação de compra:

1. Resolve o `UserProfile` pelo e-mail do JWT.
2. Busca pelo hash do token se já existe assinatura — se existe e pertence a outro usuário, rejeita (`PURCHASE_ALREADY_BOUND`).
3. Consulta a Google Play Developer API via `GooglePlaySubscriptionGateway.getSubscription(productId, token)`.
4. Valida que o `accountBinding` recebido coincide com o hash esperado (`SHA-256("nutrity:" + userId)`).
5. Se a compra está `PENDING`, retorna 422 sem persistir.
6. Persiste `GooglePlaySubscription` (nova ou atualizada com `applyAuthoritativeState`).
7. Chama `acknowledge()` se ainda não foi reconhecida.
8. Atualiza projeção Premium em `UserProfile`.
9. Emite auditoria em todos os caminhos (sucesso e falha).

Idempotência: se o token já foi persistido para o mesmo usuário, atualiza o estado com os dados mais recentes da Google Play sem criar duplicata.

#### `SubscriptionRestoreService`
**Arquivo:** [`SubscriptionRestoreService.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionRestoreService.java)

Itera sobre a lista de compras enviadas e delega cada uma para `SubscriptionValidationService.validate(...)` com `EventType.RESTORE`. Retorna o primeiro resumo que conceda entitlement, ou o estado atual se nenhuma conceder.

#### `SubscriptionLifecycleSyncService`
**Arquivo:** [`SubscriptionLifecycleSyncService.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionLifecycleSyncService.java)

Responsável por sincronizar o estado de uma assinatura já conhecida com a Google Play. Usado por:
- `GooglePlayRtdnConsumer` (notificações em tempo real via Pub/Sub)
- `SubscriptionReconciliationJob` (job periódico)

Fluxo:
1. Busca a assinatura pelo hash do token.
2. Consulta Google Play Developer API.
3. Chama `applyAuthoritativeState` ou `markVoided` dependendo do resultado.
4. Atualiza projeção Premium do usuário.
5. Emite auditoria.
6. Usa `OptimisticConflictRetrier` para lidar com conflitos de versão JPA otimista.

#### `OptimisticConflictRetrier`
**Arquivo:** [`OptimisticConflictRetrier.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/OptimisticConflictRetrier.java)

Executa operações com retry automático em caso de `ObjectOptimisticLockingFailureException`, necessário quando RTDN e job de reconciliação tentam atualizar a mesma assinatura simultaneamente.

### 4.3 Entidades de domínio

#### `GooglePlaySubscription`
**Arquivo:** [`GooglePlaySubscription.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/GooglePlaySubscription.java)

Entidade JPA central. Campos relevantes:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID string | Identificador interno |
| `version` | long | Controle otimista JPA (`@Version`) |
| `userId` | string | FK ao `UserProfile` |
| `provider` | string | Sempre `"GOOGLE_PLAY"` |
| `purchaseTokenEncrypted` | string | Token cifrado com AES-256-GCM (ver §4.6) |
| `purchaseTokenHash` | string | SHA-256 do token em texto claro — chave única |
| `productId` | string | ID do produto |
| `basePlanId` | string | ID do plano base |
| `offerId` | string | ID da oferta promocional (nullable) |
| `status` | `SubscriptionStatus` | Estado atual |
| `startedAt` | `OffsetDateTime` | Início da assinatura |
| `expiresAt` | `OffsetDateTime` | Expiração (nullable) |
| `nextBillingAt` | `OffsetDateTime` | Próxima cobrança (nullable) |
| `autoRenewEnabled` | boolean | Renovação automática ativa |
| `accountBindingHash` | string | SHA-256 do accountBinding |
| `linkedPurchaseTokenHash` | string | Hash do token anterior em caso de upgrade/downgrade |
| `lastValidatedAt` | `OffsetDateTime` | Última validação com Google Play |

`applyAuthoritativeState(providerSubscription, validatedAt)` valida a transição de estado via `SubscriptionStatus.canTransitionTo()` antes de aplicar.

#### `SubscriptionAuditEvent`
**Arquivo:** [`SubscriptionAuditEvent.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/SubscriptionAuditEvent.java)

Registro imutável de auditoria. Campos:

| Campo | Valores possíveis |
|-------|------------------|
| `eventType` | `VALIDATION`, `ACKNOWLEDGEMENT`, `RTDN`, `RECONCILIATION`, `RESTORE`, `STATUS_CHANGE` |
| `source` | `APP`, `GOOGLE_PLAY`, `SCHEDULED_JOB` |
| `outcome` | `SUCCESS`, `REJECTED`, `RETRYABLE_FAILURE`, `FAILED` |
| `previousStatus` | Estado anterior da assinatura |
| `newStatus` | Novo estado |
| `providerReferenceMasked` | Primeiros/últimos caracteres do token — nunca integralmente |

#### `SubscriptionReconciliationCursor`
**Arquivo:** [`SubscriptionReconciliationCursor.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/SubscriptionReconciliationCursor.java)

Armazena o cursor paginado do job de reconciliação por provider, evitando reprocessar assinaturas já reconciliadas em execuções anteriores.

### 4.4 Infraestrutura Google Play

#### `GooglePlayDeveloperSubscriptionGateway`
**Arquivo:** [`GooglePlayDeveloperSubscriptionGateway.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePlayDeveloperSubscriptionGateway.java)

Implementa `GooglePlaySubscriptionGateway` usando `RestClient` (Spring 6) e autenticação via `google-auth-library` (Service Account com escopo `androidpublisher`).

Operações mapeadas para a **Google Play Developer API v3**:

| Método | Endpoint |
|--------|---------|
| `listOffers()` | `GET /androidpublisher/v3/applications/{pkg}/subscriptions` |
| `getSubscription(productId, token)` | `GET .../purchases/subscriptionsv2/tokens/{token}` |
| `acknowledge(productId, token)` | `POST .../purchases/subscriptions/{productId}/tokens/{token}:acknowledge` |

O access token OAuth2 é renovado automaticamente quando próximo de expirar (controle via `GoogleCredentials.refreshIfExpired()`).

#### `GooglePlayRtdnConsumer`
**Arquivo:** [`GooglePlayRtdnConsumer.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePlayRtdnConsumer.java)

Processa notificações **Real-time Developer Notifications (RTDN)** enviadas pelo Google Cloud Pub/Sub via push HTTP.

Fluxo de processamento:
1. Valida o token OIDC no header `Authorization` via `PubSubPushOidcAuthenticator`.
2. Verifica se o `subscription` (nome da assinatura Pub/Sub) está na lista permitida.
3. Decodifica o payload Base64 da mensagem.
4. Extrai `purchaseToken` e `subscriptionId` de `subscriptionNotification`.
5. Delega para `SubscriptionLifecycleSyncService.synchronize(...)`.

**Endpoint:** `POST /subscriptions/rtdn`  
**Controlador:** [`GooglePlayRtdnController.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/application/api/GooglePlayRtdnController.java)

#### `PubSubPushOidcAuthenticator` / `GooglePubSubPushOidcAuthenticator`
**Arquivo:** [`GooglePubSubPushOidcAuthenticator.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePubSubPushOidcAuthenticator.java)

Verifica o token OIDC enviado pelo Google Cloud Pub/Sub no header `Authorization: Bearer <token>`, garantindo que o webhook RTDN só aceite chamadas legítimas do Google.

### 4.5 Renovação automática e reconciliação

#### Modelo de atualização de estado

A Google Play atualiza os estados da assinatura por dois canais:

| Canal | Latência | Implementação |
|-------|----------|---------------|
| RTDN (Pub/Sub Push) | Segundos | `GooglePlayRtdnConsumer` → `SubscriptionLifecycleSyncService` |
| Job periódico | Configurável (padrão: 1h) | `SubscriptionReconciliationJob` |

#### `SubscriptionReconciliationJob`
**Arquivo:** [`SubscriptionReconciliationJob.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/subscription/SubscriptionReconciliationJob.java)

Job `@Scheduled` que varre assinaturas em estados "vivos" (`PENDING`, `ACTIVE`, `TRIAL`, `GRACE_PERIOD`, `CANCELED_ACTIVE`, `SUSPENDED`) e revalida com a Google Play.

- Paginado com cursor persistido em `SubscriptionReconciliationCursor`.
- Tamanho de página e cron configuráveis via `nutrity.subscription.google-play.reconciliation.*`.
- Habilitado por `reconciliation.enabled = true`.

### 4.6 Segurança do token de compra

**Arquivo:** [`PurchaseTokenProtector.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/PurchaseTokenProtector.java)

O `purchaseToken` nunca é armazenado em texto claro no banco. Dois valores são persistidos:

| Campo | Como gerado |
|-------|------------|
| `purchaseTokenHash` | `SHA-256(token)` em hex — usado como chave única de busca |
| `purchaseTokenEncrypted` | `"v1:" + Base64(IV ‖ AES-256-GCM(token))` — permite recuperar o token para consultar a Google Play |

A chave AES-256 é configurada via `GOOGLE_PLAY_TOKEN_ENCRYPTION_KEY` (32 bytes em Base64). O IV é aleatório por cifragem.

O `reveal(protectedToken)` desfaz a proteção quando precisar chamar a Google Play API com o token original.

### 4.7 Auditoria

**Arquivo:** [`SubscriptionObservability.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/SubscriptionObservability.java)

Toda operação relevante gera um `SubscriptionAuditEvent` persistido. O `providerReferenceMasked` armazena apenas os primeiros e últimos caracteres do token — nunca o token completo.

Eventos auditados:
- Validação de compra (sucesso, rejeição, falha temporária)
- Acknowledgement
- Notificações RTDN
- Reconciliação periódica
- Restauração de compra
- Mudanças de status

### 4.8 Configuração

**Arquivo:** [`GooglePlaySubscriptionProperties.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/config/subscription/GooglePlaySubscriptionProperties.java)

Prefixo: `nutrity.subscription.google-play`

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `enabled` | boolean | Habilita a feature completa |
| `package-name` | string | `br.com.nutrity.vfpsolution` |
| `service-account-credentials` | string | JSON da conta de serviço ou caminho para arquivo |
| `token-encryption-key` | string | Base64 de 32 bytes (AES-256) |
| `api-base-url` | string | `https://androidpublisher.googleapis.com` |
| `request-timeout` | Duration | Padrão: 10s |
| `rtdn.enabled` | boolean | Habilita recebimento de RTDN via Pub/Sub |
| `rtdn.subscription-name` | string | Nome da assinatura Pub/Sub |
| `rtdn.push-audience` | string | Audience esperada no token OIDC |
| `rtdn.service-account-email` | string | E-mail da SA do Pub/Sub (validação OIDC) |
| `reconciliation.enabled` | boolean | Habilita job periódico |
| `reconciliation.cron` | string | Cron expression (padrão: toda hora) |
| `reconciliation.page-size` | int | Registros por execução (padrão: 100) |

---

## 5. Modelo de dados

Tabelas criadas pela feature (JPA + Flyway/schema-auto):

### `google_play_subscriptions`

```sql
CREATE TABLE google_play_subscriptions (
    id                       VARCHAR(36)    NOT NULL PRIMARY KEY,
    version                  BIGINT         NOT NULL DEFAULT 0,
    user_id                  VARCHAR(24)    NOT NULL,
    provider                 VARCHAR(32)    NOT NULL,
    purchase_token_encrypted VARCHAR(4096)  NOT NULL,
    purchase_token_hash      VARCHAR(64)    NOT NULL UNIQUE,
    product_id               VARCHAR(255)   NOT NULL,
    base_plan_id             VARCHAR(255),
    offer_id                 VARCHAR(255),
    status                   VARCHAR(32)    NOT NULL,
    started_at               TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at               TIMESTAMP WITH TIME ZONE,
    next_billing_at          TIMESTAMP WITH TIME ZONE,
    auto_renew_enabled       BOOLEAN        NOT NULL,
    account_binding_hash     VARCHAR(64)    NOT NULL,
    linked_purchase_token_hash VARCHAR(64),
    last_validated_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at               TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at               TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_google_play_subscription_user   ON google_play_subscriptions(user_id);
CREATE INDEX idx_google_play_subscription_status ON google_play_subscriptions(status);
```

### `subscription_audit_events`

```sql
CREATE TABLE subscription_audit_events (
    id                       VARCHAR(36)  NOT NULL PRIMARY KEY,
    subscription_id          VARCHAR(36),
    provider_event_id        VARCHAR(255) UNIQUE,
    event_type               VARCHAR(32)  NOT NULL,
    source                   VARCHAR(32)  NOT NULL,
    correlation_id           VARCHAR(100) NOT NULL,
    outcome                  VARCHAR(32)  NOT NULL,
    previous_status          VARCHAR(32),
    new_status               VARCHAR(32),
    provider_reference_masked VARCHAR(80),
    occurred_at              TIMESTAMP WITH TIME ZONE NOT NULL
);
```

### `subscription_reconciliation_cursors`

```sql
CREATE TABLE subscription_reconciliation_cursors (
    provider     VARCHAR(32)   NOT NULL PRIMARY KEY,
    last_id      VARCHAR(36),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL
);
```

---

## 6. Estados da assinatura e máquina de transições

### Enum `SubscriptionStatus` (BFF)

| Estado | Concede Premium? | Descrição |
|--------|-----------------|-----------|
| `PENDING` | ❌ | Compra registrada, aguardando confirmação da Google Play |
| `ACTIVE` | ✅ | Assinatura ativa e válida |
| `TRIAL` | ✅ | Em período de trial gratuito |
| `GRACE_PERIOD` | ✅ | Falha de pagamento, ainda em período de graça |
| `CANCELED_ACTIVE` | ✅ | Cancelada mas com período pago vigente |
| `SUSPENDED` | ❌ | Suspensa por problema de pagamento |
| `EXPIRED` | ❌ | Período expirado |
| `REFUNDED` | ❌ | Reembolsada |
| `REVOKED` | ❌ | Revogada pela Google Play |

### Transições permitidas

```
PENDING          → ACTIVE, TRIAL, EXPIRED, REFUNDED, REVOKED
ACTIVE           → TRIAL, GRACE_PERIOD, CANCELED_ACTIVE, SUSPENDED, EXPIRED, REFUNDED, REVOKED
TRIAL            → ACTIVE, GRACE_PERIOD, CANCELED_ACTIVE, SUSPENDED, EXPIRED, REFUNDED, REVOKED
GRACE_PERIOD     → ACTIVE, CANCELED_ACTIVE, SUSPENDED, EXPIRED, REFUNDED, REVOKED
SUSPENDED        → ACTIVE, EXPIRED, REFUNDED, REVOKED
CANCELED_ACTIVE  → ACTIVE, EXPIRED, REFUNDED, REVOKED
EXPIRED          → ACTIVE, TRIAL  (reativação após pagamento)
REFUNDED         → ACTIVE, TRIAL  (compra de nova assinatura)
REVOKED          → ACTIVE, TRIAL  (compra de nova assinatura)
```

Transições inválidas lançam `IllegalStateException` no método `applyAuthoritativeState`.

---

## 7. Segurança

| Ameaça | Mitigação |
|--------|-----------|
| Token de compra interceptado | Armazenado criptografado (AES-256-GCM), exposto apenas por hash em logs |
| Compra forjada pelo app | BFF valida com Google Play API antes de qualquer ativação |
| Reutilização de compra por outra conta | `accountBinding = SHA-256("nutrity:" + userId)` verificado pelo BFF contra Google Play |
| Webhook RTDN falsificado | OIDC token obrigatório (`PubSubPushOidcAuthenticator`) |
| Concorrência em atualizações | `@Version` JPA + `OptimisticConflictRetrier` |
| Log de dados sensíveis | `providerReferenceMasked` — nunca token integral em audit |
| Chave de criptografia no app | `GOOGLE_PLAY_TOKEN_ENCRYPTION_KEY` apenas no servidor |
| Segredo da Service Account | Configurado via variável de ambiente, nunca commitado |

---

## 8. Credenciais e configuração Google — guia completo

O Nutrity usa **duas integrações distintas com o Google**, que compartilham o mesmo Google Cloud Project mas têm credenciais e pontos de configuração diferentes:

| Integração | Para que serve | Onde se configura |
|-----------|----------------|-------------------|
| **Google Sign-In (OAuth)** | Login do usuário, emissão de `idToken`/`accessToken` | Google Cloud Console → Credenciais OAuth 2.0 + `google-services.json` no app |
| **Google Play Billing** | Processar pagamentos e assinaturas no app | Google Play Console (produtos) — o SDK já usa a conta do dispositivo, sem chave extra no app |
| **Google Play Developer API** | BFF valida compras e consulta status de assinatura | Google Cloud Console → Service Account com acesso ao Google Play Console |
| **Cloud Pub/Sub (RTDN)** | Google Push notificações de ciclo de vida para o BFF | Google Cloud Console → tópico Pub/Sub + assinatura push com autenticação OIDC |

---

### 8.1 Visão geral: dois contextos, mesma conta Google

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Google Cloud Project                              │
│                                                                      │
│  ┌──────────────────┐         ┌──────────────────────────────────┐  │
│  │  OAuth 2.0       │         │  Service Account                 │  │
│  │  (Google Sign-In)│         │  (BFF → Google Play API)         │  │
│  │                  │         │                                  │  │
│  │ Client ID        │         │  JSON credentials                │  │
│  │ (Android + Web)  │         │  → GOOGLE_PLAY_SERVICE_ACCOUNT   │  │
│  └────────┬─────────┘         └───────────────┬──────────────────┘  │
│           │                                   │                      │
└───────────┼───────────────────────────────────┼──────────────────────┘
            │                                   │
            ▼                                   ▼
     App Flutter                           BFF Spring Boot
   (google_sign_in)                   (GooglePlayDeveloperAPI)
```

---

### 8.2 Login OAuth Google (Google Sign-In)

O app usa o pacote [`google_sign_in`](https://pub.dev/packages/google_sign_in) para autenticar o usuário. O fluxo emite um `idToken` e/ou `accessToken` que o BFF valida chamando `https://oauth2.googleapis.com/tokeninfo`.

#### Onde configurar no Google Cloud Console

1. Acesse **APIs & Serviços → Credenciais**.
2. Crie uma **OAuth 2.0 Client ID** do tipo **Android**:
   - Package name: `br.com.nutrity.vfpsolution`
   - SHA-1 do keystore de release (e do keystore de debug para testes)
3. Crie uma **OAuth 2.0 Client ID** do tipo **Web application** (necessária para que o `idToken` tenha uma audience válida que o BFF possa verificar).

#### Onde o arquivo `google-services.json` entra

O arquivo `google-services.json` gerado pelo Google Cloud Console (ou Firebase Console) deve ser colocado em:

```
app/android/app/google-services.json
```

> ⚠️ **Este arquivo está no `.gitignore` e NÃO deve ser commitado.** Ele contém o `client_id` Android e o `client_id` Web (server client ID) usados pelo SDK `google_sign_in` para emitir tokens com a audience correta.

**Estrutura relevante do `google-services.json`:**
```json
{
  "project_info": {
    "project_id": "nutrity-app"
  },
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "br.com.nutrity.vfpsolution"
        }
      },
      "oauth_client": [
        {
          "client_id": "XXXXXXX.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": { "package_name": "br.com.nutrity.vfpsolution", "certificate_hash": "<SHA1>" }
        },
        {
          "client_id": "YYYYYYY.apps.googleusercontent.com",
          "client_type": 3
        }
      ]
    }
  ]
}
```

O `client_type: 3` é o **Web Client ID** — é o valor que aparece como `aud` no `idToken` e que precisa ser configurado no BFF via `GOOGLE_OAUTH_ALLOWED_AUDIENCES`.

#### Como o app usa (código)

**Arquivo:** [`app/lib/services/auth/google_auth_service.dart`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/app/lib/services/auth/google_auth_service.dart)

```dart
GoogleSignIn.standard(scopes: ['email'])
```

O SDK lê automaticamente as configurações do `google-services.json` gerado pelo Gradle. Não há `clientId` hardcoded no código Dart.

#### Como o BFF valida o token

**Arquivo:** [`bff/src/main/resources/application.yml`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/resources/application.yml) — trecho relevante:

```yaml
nutrity:
  auth:
    google:
      enabled: ${GOOGLE_OAUTH_VALIDATION_ENABLED:true}
      token-info-url: ${GOOGLE_OAUTH_TOKEN_INFO_URL:https://oauth2.googleapis.com/tokeninfo}
      allowed-audiences: ${GOOGLE_OAUTH_ALLOWED_AUDIENCES:}
```

**Arquivo:** [`GoogleOAuthValidator.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/domain/service/user/GoogleOAuthValidator.java)

O BFF chama `GET https://oauth2.googleapis.com/tokeninfo?id_token=<token>` e verifica:
- `email_verified == true`
- `aud` está na lista `GOOGLE_OAUTH_ALLOWED_AUDIENCES` (se configurada)

**`GOOGLE_OAUTH_ALLOWED_AUDIENCES`** deve conter o **Web Client ID** do Google Cloud Console (o `client_type: 3` do `google-services.json`).

---

### 8.3 Google Play Billing (pagamento e assinatura)

O fluxo de pagamento usa exclusivamente o SDK oficial `in_app_purchase` / `in_app_purchase_android` — **não há chave de API no app para o Google Play Billing**. A Google Play reconhece o app pela combinação:

- **Package name** (`applicationId` no `build.gradle.kts`): `br.com.nutrity.vfpsolution`
- **Assinatura digital do APK** (o keystore usado para assinar o build)

#### Onde configurar no Google Play Console

1. Acesse **Google Play Console → Monetização → Produtos → Assinaturas**.
2. Crie os produtos com os IDs configurados em `NUTRITY_GOOGLE_PLAY_PRODUCT_IDS` (ex.: `premium_monthly`, `premium_yearly`).
3. Para cada produto, crie **planos base** (`basePlanId`) e defina preços, período de cobrança e elegibilidade.

O app consome esses dados via `InAppPurchase.queryProductDetails(_productIds)` — o SDK autentica automaticamente usando a conta Google do dispositivo.

#### SHA-1 do keystore de release

Para que o Google Play aceite a assinatura do APK:

```bash
keytool -list -v -keystore <caminho/release.keystore> -alias <alias>
# Copie o SHA1 e SHA256 exibidos
```

O SHA-1 também é necessário na configuração do **OAuth 2.0 Client ID Android** no Google Cloud Console (para que o `idToken` seja válido em builds de release).

---

### 8.4 Service Account (BFF ↔ Google Play Developer API)

O BFF precisa de uma **Service Account** do Google Cloud para chamar a **Google Play Developer API** e validar/consultar assinaturas. Esta é a credencial mais sensível da feature.

#### Como criar

1. No **Google Cloud Console → IAM & Admin → Contas de serviço**:
   - Crie uma conta: ex. `nutrity-bff@<project>.iam.gserviceaccount.com`
   - Gere uma chave JSON e salve com segurança.
2. No **Google Play Console → Configuração → Contas de serviço e API**:
   - Vincule a conta de serviço ao app.
   - Conceda a permissão **Gerenciador financeiro** (necessária para `GET subscriptionsv2` e `POST acknowledge`).

#### Como configurar no BFF

A chave JSON pode ser fornecida de duas formas via `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS`:

```bash
# Opção 1: conteúdo JSON inline (útil em variáveis de ambiente de containers)
GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS='{"type":"service_account","project_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n..."}'

# Opção 2: caminho para arquivo no sistema de arquivos do servidor
GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS='/run/secrets/google-play-sa.json'

# Opção 3: deixar vazio → usa Application Default Credentials (ADC)
# Útil em ambientes GCP (Cloud Run, GKE) com Workload Identity
GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS=''
```

**Arquivo de configuração:** [`bff/src/main/resources/application.yml`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/resources/application.yml)

```yaml
nutrity:
  subscription:
    google-play:
      service-account-credentials: ${GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS:}
```

**Arquivo de uso:** [`GooglePlayDeveloperSubscriptionGateway.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePlayDeveloperSubscriptionGateway.java)

O gateway usa `google-auth-library` para criar um `GoogleCredentials` com escopo `AndroidPublisherScopes.ANDROIDPUBLISHER`. O access token OAuth2 é renovado automaticamente quando próximo de expirar.

---

### 8.5 RTDN via Cloud Pub/Sub

As notificações em tempo real (RTDN) chegam ao BFF via um **push HTTP do Google Cloud Pub/Sub**. Para autenticar que a chamada vem realmente do Google, o Pub/Sub envia um **OIDC JWT** no header `Authorization`.

#### Como configurar no Google Cloud Console

1. **Crie um tópico Pub/Sub**: ex. `nutrity-play-rtdn`.
2. **Vincule ao Google Play Console**: em **Monetização → Notificações em tempo real**, informe o nome completo do tópico (`projects/<project>/topics/nutrity-play-rtdn`).
3. **Crie uma assinatura push**:
   - Endpoint: `https://<seu-bff>/bff-service/subscriptions/rtdn`
   - Habilitar autenticação: selecione uma **conta de serviço** (pode ser diferente da SA de billing) e defina a **audience** (ex.: `https://<seu-bff>/bff-service/subscriptions/rtdn`).

#### Como configurar no BFF

```yaml
nutrity:
  subscription:
    google-play:
      rtdn:
        enabled: ${GOOGLE_PLAY_RTDN_ENABLED:false}
        subscription-name: ${GOOGLE_PLAY_RTDN_SUBSCRIPTION:}         # projects/<p>/subscriptions/<sub>
        push-audience: ${GOOGLE_PLAY_RTDN_PUSH_AUDIENCE:}            # audience configurada na assinatura push
        service-account-email: ${GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT_EMAIL:}  # SA que o Pub/Sub usa para assinar o JWT
```

**Arquivo de validação:** [`GooglePubSubPushOidcAuthenticator.java`](/home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePubSubPushOidcAuthenticator.java)

O BFF verifica:
1. O JWT no header `Authorization: Bearer <oidc-token>`.
2. Que a `aud` (audience) bate com `GOOGLE_PLAY_RTDN_PUSH_AUDIENCE`.
3. Que o `email` do JWT bate com `GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT_EMAIL`.

---

### 8.6 Resumo: onde cada credencial fica

| Credencial | Formato | Onde fica | Quem usa |
|-----------|---------|-----------|----------|
| `google-services.json` | JSON gerado pelo Google Cloud/Firebase Console | `app/android/app/google-services.json` (no `.gitignore`) | SDK `google_sign_in` no app Flutter |
| **SHA-1 do keystore** | Hash hex | Google Cloud Console (OAuth Android Client) + Google Play Console (upload) | Google valida a assinatura do APK |
| **Web Client ID** (OAuth) | String `XXXXXXXXX.apps.googleusercontent.com` | `google-services.json` + variável `GOOGLE_OAUTH_ALLOWED_AUDIENCES` no BFF | BFF valida o `aud` do `idToken` |
| **Service Account JSON** | JSON com chave privada RSA | Variável de ambiente `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` no BFF (nunca no app) | BFF chama Google Play Developer API |
| **Token Encryption Key** | Base64 de 32 bytes (AES-256) | Variável de ambiente `GOOGLE_PLAY_TOKEN_ENCRYPTION_KEY` no BFF | BFF cifra os tokens de compra no banco |
| **SA de Pub/Sub (OIDC)** | E-mail da conta de serviço | Variável `GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT_EMAIL` no BFF | BFF autentica chamadas RTDN do Pub/Sub |

> **Regra de ouro:** nenhum segredo da Service Account, chave de criptografia ou Client Secret jamais deve estar no código do app Flutter ou em arquivos commitados no repositório.

---

## 9. Variáveis de ambiente

### BFF

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `GOOGLE_OAUTH_VALIDATION_ENABLED` | Não (padrão `true`) | Habilita validação do token Google no BFF |
| `GOOGLE_OAUTH_ALLOWED_AUDIENCES` | Recomendada | Web Client ID do Google Cloud (`XXXXXXXXX.apps.googleusercontent.com`); se vazio, qualquer audience é aceita |
| `GOOGLE_OAUTH_TOKEN_INFO_URL` | Não | URL de validação de token; padrão `https://oauth2.googleapis.com/tokeninfo` |
| `GOOGLE_PLAY_SUBSCRIPTION_ENABLED` | Sim (para ativar) | `true` para habilitar a feature de assinatura |
| `GOOGLE_PLAY_PACKAGE_NAME` | Sim | Package ID do app Android (`br.com.nutrity.vfpsolution`) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` | Sim | JSON da conta de serviço ou caminho `file:/…` — deixar vazio usa ADC |
| `GOOGLE_PLAY_TOKEN_ENCRYPTION_KEY` | Sim | Base64 de 32 bytes (AES-256) para cifrar tokens de compra no banco |
| `GOOGLE_PLAY_RTDN_ENABLED` | Não | `true` para receber notificações RTDN via Pub/Sub |
| `GOOGLE_PLAY_RTDN_SUBSCRIPTION` | Se RTDN ativo | Nome completo da assinatura Pub/Sub (`projects/<p>/subscriptions/<s>`) |
| `GOOGLE_PLAY_RTDN_PUSH_AUDIENCE` | Se RTDN ativo | Audience configurada na assinatura push do Pub/Sub |
| `GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT_EMAIL` | Se RTDN ativo | E-mail da SA que o Pub/Sub usa para assinar o JWT OIDC |
| `GOOGLE_PLAY_RECONCILIATION_ENABLED` | Não | `true` para habilitar o job periódico de reconciliação |
| `GOOGLE_PLAY_RECONCILIATION_CRON` | Não | Cron expression (padrão: `0 0 * * * *` = toda hora) |
| `GOOGLE_PLAY_RECONCILIATION_PAGE_SIZE` | Não | Registros por execução do job (padrão: `100`) |

### App Flutter (dart-define)

| Define | Padrão | Descrição |
|--------|--------|-----------|
| `NUTRITY_GOOGLE_PLAY_PRODUCT_IDS` | `premium_monthly,premium_yearly` | IDs dos produtos cadastrados no Google Play Console |
| `NUTRITY_ANDROID_PACKAGE_NAME` | `br.com.nutrity.vfpsolution` | Usado na URL de gerenciamento de assinatura |

---

## 10. Inicialização e checklist de deploy

### Pré-requisitos no Google Play Console

- [ ] Produtos de assinatura criados com os IDs configurados em `NUTRITY_GOOGLE_PLAY_PRODUCT_IDS`
- [ ] Planos base (`basePlanId`) publicados e em estado `ACTIVE`
- [ ] Service Account criada com permissão **Gerenciador financeiro** no Google Play Console
- [ ] Tópico e assinatura Pub/Sub configurados no Google Cloud (se RTDN ativo)
- [ ] URL do webhook RTDN (`POST /subscriptions/rtdn`) exposta com HTTPS

### Geração da chave de criptografia

```bash
openssl rand -base64 32
# Resultado → GOOGLE_PLAY_TOKEN_ENCRYPTION_KEY
```

### Fluxo de teste end-to-end

1. Configurar um **tester** no Google Play Console (licença de teste).
2. Instalar build de debug no dispositivo com a conta de tester.
3. Selecionar o plano Premium na tela `PlanSelectionPage`.
4. Confirmar compra na tela Google Play.
5. Verificar logs do BFF: `outcome=SUCCESS`, `status=ACTIVE` em `subscription_audit_events`.
6. Confirmar que `UserProfile.isPremium = true` no banco.
7. Cancelar a assinatura no Google Play → verificar RTDN ou aguardar reconciliação → `status=CANCELED_ACTIVE` (Premium mantido até expiração).
8. Aguardar expiração → `status=EXPIRED`, `isPremium = false`.

### Health checks

O BFF expõe `GET /actuator/health` com indicadores:
- `GooglePlaySubscriptionHealthIndicator` — verifica se a API da Google Play responde
