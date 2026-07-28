# Plano de Implementação: Assinatura Premium e Google Play Billing

**Branch**: `005-assinatura-premium-google-play` | **Data**: 2026-07-28 | **Spec**: [spec.md](spec.md)

## Resumo

Implementar contratação de assinatura Premium Android pela Google Play com o BFF como fonte de verdade do direito de acesso. O aplicativo mantém a tela Material 3 de planos, exige autenticação Google antes de iniciar o pagamento, executa a compra oficial e transmite o token de compra ao BFF. O BFF valida e reconhece a compra na Google Play, persiste o ciclo de vida e atualiza o acesso por notificações em tempo real e reconciliação horária.

## Contexto Técnico

**Linguagem/versão**: Dart >=3.0.0 <4.0.0 com Flutter; Java 21 com Spring Boot 3.3.4.

**Dependências principais**: Flutter Material 3, Provider/ChangeNotifier, `google_sign_in`, SQLite; Spring Web, Security, Validation, JPA, Flyway, OpenFeign e Actuator. Adicionar uma biblioteca Flutter de Billing compatível com Google Play e um cliente autenticado da Google Play Developer API no BFF, ambos encapsulados por contratos internos.

**Armazenamento**: SQLite apenas para cache de sessão e apresentação no aplicativo; PostgreSQL/H2, JPA e Flyway no BFF para assinaturas, eventos e cursor de reconciliação. O BFF permanece como fonte de verdade para o acesso Premium.

**Testes**: `flutter test`, testes de widget, unitários e de integração/contrato no app; `./mvnw test`, testes unitários, de integração JPA e de contrato HTTP no BFF. A Google Play, Pub/Sub e Billing devem ser substituídos por doubles/fixtures na suíte padrão.

**Plataforma alvo**: Android distribuído pela Google Play; BFF HTTP Java 21.

**Tipo de projeto**: Monorepo mobile Flutter + BFF.

**Metas de desempenho**:
- Apresentar o estado de processamento assim que a compra ou validação iniciar.
- Reconciliar assinaturas ativas no BFF em até uma hora.
- Não liberar conteúdo Premium antes da confirmação pelo BFF.

**Restrições**:
- Pagamento somente pelo fluxo oficial da Google Play; nenhum dado de cartão no Nutrity.
- Autenticação Google obrigatória antes de iniciar a compra para vincular uma identidade interna ofuscada à compra.
- Segredos da conta de serviço e tokens de compra não podem aparecer no aplicativo ou em logs.
- RTDN é gatilho, não fonte de verdade: todo evento exige consulta posterior à Google Play.
- Trocas de plano ficam exclusivamente na tela de gerenciamento da Google Play.
- Operações locais de refeições permanecem disponíveis sem rede; compra, autenticação, validação e sincronização de status podem exigir rede.

**Escopo**: Uma nova feature Flutter de assinatura, extensões ao perfil e onboarding existentes, e um módulo de assinatura no BFF com persistência, validação, RTDN e reconciliação.

## Constitution Check

### Pré-pesquisa

| Princípio | Verificação | Resultado |
|---|---|---|
| Idioma | Todos os artefatos desta feature estão em português do Brasil. | Aprovado |
| Simplicidade/MVP | Uma única integração de cobrança e uma única fonte de verdade no BFF; troca de planos delegada à Google Play. | Aprovado |
| Offline first | Refeições locais não dependem da assinatura remota; falhas remotas preservam o último estado confirmado apenas para apresentação. | Aprovado |
| Fronteiras | Billing e Google Play ficam em adapters; domínio depende de portas. | Aprovado |
| Material 3 e acessibilidade | Paywall e perfil reutilizam tema/tokens, tratam carregamento, pendência, erro e sucesso. | Aprovado |
| Dados | Mudanças do BFF usam Flyway; cache do app fica separado do modelo remoto. | Aprovado |
| Testes por risco | Regras de entitlement, idempotência e estados terão testes determinísticos; adapters terão contrato/integração com doubles. | Aprovado |
| BFF/contratos | Endpoints versionados, autenticação, validação e idempotência documentados em `contracts/`. | Aprovado |
| Segurança/observabilidade | Segredos externos no BFF; logs estruturados sem token integral; auditoria e métricas previstas. | Aprovado |

### Pós-design

Os artefatos em [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/) e [quickstart.md](quickstart.md) preservam os mesmos gates. Não há exceção arquitetural pendente.

## Estrutura do Projeto

### Documentação desta feature

```text
specs/005-assinatura-premium-google-play/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── subscription-api.md
│   └── google-play-notifications.md
└── tasks.md                    # Gerado posteriormente por /speckit-tasks
```

### Código-fonte

```text
app/
├── lib/
│   ├── features/
│   │   ├── onboarding/          # seleção de plano e paywall
│   │   └── home/                # perfil e estado Premium
│   └── services/
│       ├── auth/                # autenticação Google
│       ├── bff/                 # cliente e serviços do BFF
│       └── subscription/        # sessão/cached settings e portas de Billing
└── test/
    ├── unit/
    └── widget/

bff/
├── src/main/java/br/com/nutrity/vfpsolution/
│   ├── application/api/         # controllers e contratos HTTP
│   ├── application/             # casos de uso de assinatura
│   ├── domain/                  # entidades, estados e portas
│   ├── infrastructure/          # JPA, Google Play, RTDN e agendamento
│   └── config/                  # propriedades e segurança
├── src/main/resources/db/migration/
└── src/test/
```

**Decisão de estrutura**: Reutilizar `services/subscription` e as telas existentes no app. No BFF, manter controllers finos, regras de entitlement no domínio/aplicação e Google Play/Pub/Sub como adapters de infraestrutura.

## Sequência de Implementação

1. Adicionar contratos do domínio para catálogo, compra, validação e consulta de entitlement; implementar doubles para testes.
2. Criar o adapter Flutter da Google Play, recuperar compras no início/retorno ao foreground e integrar com `SubscriptionService`.
3. Substituir preços estáticos do paywall por ofertas retornadas da Google Play; autenticar antes da compra e encaminhar estados de carregamento, pendência, cancelamento e falha.
4. Criar migrations e entidades de assinatura, evento de auditoria e cursor de reconciliação.
5. Implementar adapter da Google Play Developer API, validação do token, reconhecimento idempotente e atualização do perfil efetivo.
6. Expor endpoints autenticados de catálogo/validação/status/restauração/gerenciamento e proteger recursos Premium pelo entitlement do servidor.
7. Implementar consumidor de RTDN e a reconciliação horária com consulta autoritativa; adicionar métricas, logs mascarados e alertas de falha.
8. Integrar o perfil do aplicativo com status, data de término/cobrança e redirecionamento de gerenciamento.
9. Executar os testes por risco e o quickstart em ambiente de testes da Google Play.

## Complexidade

| Violação | Por que é necessária | Alternativa simples rejeitada porque |
|---|---|---|
| Integração com Google Play e RTDN | Pagamentos, renovação e revogação precisam de fonte de verdade externa. | Confiar no app ou validar somente durante login permite fraude e status obsoleto. |
| Reconciliação horária | Cobre eventos RTDN atrasados ou perdidos. | Apenas RTDN não recupera perda de entrega/processamento. |
