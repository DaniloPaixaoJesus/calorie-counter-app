# Tarefas: Assinatura Premium e Google Play Billing

**Entrada**: Artefatos de design em `specs/005-assinatura-premium-google-play/`  
**Pré-requisitos**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/) e [quickstart.md](quickstart.md)

**Testes**: Obrigatórios conforme a constituição: regras de domínio/aplicação com testes unitários; adapters, migrations e contratos HTTP com testes de integração/contrato; fluxos visuais críticos com widget tests. Serviços da Google Play e Pub/Sub devem ser doubles/fixtures.

**Organização**: As tarefas são agrupadas por história de usuário para permitir implementação e validação independentes.

## Formato: `[ID] [P?] [História] Descrição`

- **[P]**: Pode ser executada em paralelo, em arquivos distintos e sem dependência pendente.
- **[US#]**: História de usuário à qual a tarefa pertence.

---

## Fase 1: Preparação

**Objetivo**: Adicionar as dependências e configurações mínimas sem alterar o comportamento da assinatura existente.

- [ ] T001 Adicionar a dependência Flutter de Google Play Billing e registrar a resolução de versões em `app/pubspec.yaml`
- [ ] T002 [P] Adicionar clientes autenticados da Google Play Developer API e Pub/Sub em `bff/pom.xml`
- [ ] T003 [P] Criar propriedades tipadas e validação de configuração para pacote Android, conta de serviço, RTDN e reconciliação em `bff/src/main/java/br/com/nutrity/vfpsolution/config/subscription/GooglePlaySubscriptionProperties.java`
- [ ] T004 [P] Adicionar variáveis de ambiente documentadas, sem segredos, em `bff/src/main/resources/application.yml`
- [ ] T005 [P] Criar fixture determinística de assinatura ativa e RTDN em `bff/src/test/resources/fixtures/google-play/subscription_active.json`
- [ ] T006 [P] Criar double controlável do Billing para testes do app em `app/test/helpers/fake_play_billing_adapter.dart`

---

## Fase 2: Fundação compartilhada

**Objetivo**: Estabelecer modelo, persistência, portas e segurança que bloqueiam todas as histórias.

**⚠️ CRÍTICO**: Concluir esta fase antes das histórias de usuário.

- [ ] T007 Criar migration de assinatura, evento de auditoria e cursor de reconciliação com unicidade global do token em `bff/src/main/resources/db/migration/V2__add_google_play_subscriptions.sql`
- [ ] T008 [P] Criar enum de estados canônicos e regra de entitlement em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/subscription/SubscriptionStatus.java`
- [ ] T009 [P] Criar entidade de assinatura e transições validadas em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/GooglePlaySubscription.java`
- [ ] T010 [P] Criar entidade de evento de auditoria sem token integral em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/SubscriptionAuditEvent.java`
- [ ] T011 [P] Criar entidade de cursor de reconciliação em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/SubscriptionReconciliationCursor.java`
- [ ] T012 Criar repositório JPA de assinatura e relacionar os repositórios de auditoria/cursor em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/persistence/subscription/GooglePlaySubscriptionJpaRepository.java`
- [ ] T013 Criar portas de domínio para catálogo, validação, reconhecimento, compras anuladas e gerenciamento da Google Play em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/subscription/GooglePlaySubscriptionGateway.java`
- [ ] T014 [P] Criar modelos de domínio do app para oferta, compra, status e resumo de assinatura em `app/lib/services/subscription/subscription_models.dart`
- [ ] T015 [P] Criar contrato abstrato de Billing do app e tipos de eventos de compra em `app/lib/services/subscription/play_billing_adapter.dart`
- [ ] T016 [P] Criar contrato do gateway do BFF para assinatura no app em `app/lib/services/subscription/subscription_bff_gateway.dart`
- [ ] T017 Implementar proteção dos endpoints de assinatura pela autenticação Google em `bff/src/main/java/br/com/nutrity/vfpsolution/config/security/GoogleUserTokenFilter.java`
- [ ] T018 Criar máscara reutilizável de referências de compra e logs estruturados em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/SubscriptionObservability.java`
- [ ] T019 [P] Criar testes de migration, unicidade do token e mapeamento JPA em `bff/src/test/java/br/com/nutrity/vfpsolution/infrastructure/persistence/subscription/GooglePlaySubscriptionPersistenceIT.java`
- [ ] T020 [P] Criar testes unitários da máquina de estados e entitlement em `bff/src/test/java/br/com/nutrity/vfpsolution/domain/subscription/SubscriptionStatusTest.java`
- [ ] T021 [P] Criar testes unitários dos modelos e portas de assinatura no app em `app/test/unit/services/subscription/subscription_models_test.dart`

**Checkpoint**: Persistência, estado canônico, contratos e segurança estão disponíveis para as histórias.

---

## Fase 3: História de Usuário 1 — Contratação da assinatura Premium (P1) 🎯 MVP

**Objetivo**: Usuário Free escolhe uma oferta, autentica antes do pagamento, conclui a compra oficial e recebe Premium somente após validação do BFF.

**Teste independente**: Com doubles de Billing e Google Play, simular oferta, login, compra concluída e validação; confirmar que o BFF retorna Premium e a UI libera o estado somente após a resposta.

### Testes da História 1

- [ ] T022 [P] [US1] Criar teste unitário de validação, vínculo ofuscado, idempotência e reconhecimento em `bff/src/test/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionValidationServiceTest.java`
- [ ] T023 [P] [US1] Criar teste de contrato para `POST /subscriptions/validate` em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SubscriptionControllerContractTest.java`
- [ ] T024 [P] [US1] Criar widget test do paywall para login antes da compra, carregamento e sucesso em `app/test/widget/features/onboarding/paywall_purchase_test.dart`
- [ ] T025 [P] [US1] Criar teste do serviço de assinatura que não ativa Premium antes da confirmação remota em `app/test/unit/services/subscription/subscription_purchase_service_test.dart`

### Implementação da História 1

- [ ] T026 [US1] Implementar adapter Flutter da Google Play, consulta de ofertas, início de compra e stream de atualizações em `app/lib/services/subscription/google_play_billing_adapter.dart`
- [ ] T027 [US1] Implementar cliente autenticado da Google Play Developer API, validação de token e reconhecimento idempotente em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePlayDeveloperSubscriptionGateway.java`
- [ ] T028 [US1] Implementar caso de uso que valida compra, verifica vínculo, persiste assinatura, audita e atualiza entitlement em `bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionValidationService.java`
- [ ] T029 [US1] Criar DTOs validados de catálogo, validação e resumo de assinatura em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/subscription/SubscriptionValidationRequest.java`
- [ ] T030 [US1] Expor catálogo e validação idempotente no controller em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SubscriptionController.java`
- [ ] T031 [US1] Implementar gateway HTTP do app para catálogo e validação em `app/lib/services/bff/subscription_bff_gateway.dart`
- [ ] T032 [US1] Integrar autenticação pré-pagamento, identificador ofuscado, compra e confirmação do BFF em `app/lib/services/subscription/subscription_service.dart`
- [ ] T033 [US1] Substituir planos/preços estáticos por ofertas da Google Play e integrar o fluxo de compra em `app/lib/features/onboarding/paywall_page.dart`
- [ ] T034 [US1] Atualizar a inicialização e injeção de adapters de assinatura em `app/lib/main.dart`
- [ ] T035 [US1] Atualizar proteções de recursos Premium para consultar o entitlement derivado da assinatura em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/persistence/PersistedPremiumStatusProvider.java`

**Checkpoint**: A contratação ativa Premium apenas após confirmação autoritativa e pode ser demonstrada com a História 1 isoladamente.

---

## Fase 4: História de Usuário 2 — Cancelamento e interrupções do fluxo (P1)

**Objetivo**: Cancelamento, compra pendente, perda de conexão e tentativas simultâneas mantêm o usuário Free e apresentam mensagem acionável.

**Teste independente**: Simular cancelamento de login/pagamento, estado pendente, queda após compra e clique duplo; confirmar que o fluxo não duplica compra nem libera Premium.

### Testes da História 2

- [ ] T036 [P] [US2] Criar testes do estado de fluxo para cancelamento, pendência e bloqueio de duplicidade em `app/test/unit/services/subscription/subscription_purchase_flow_test.dart`
- [ ] T037 [P] [US2] Criar widget tests para cancelamento, pendência, erro recuperável e botão desabilitado em `app/test/widget/features/onboarding/paywall_purchase_states_test.dart`
- [ ] T038 [P] [US2] Criar testes de contrato para resposta pendente, vínculo inválido e provider indisponível em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SubscriptionValidationErrorContractTest.java`

### Implementação da História 2

- [ ] T039 [US2] Modelar estado efêmero de processamento, pendência, cancelamento e falha recuperável em `app/lib/services/subscription/subscription_purchase_state.dart`
- [ ] T040 [US2] Tratar eventos cancelados, pendentes e reconexão de compra concluída no adapter em `app/lib/services/subscription/google_play_billing_adapter.dart`
- [ ] T041 [US2] Exibir estados acessíveis de carregamento, pendência, cancelamento e nova tentativa no paywall em `app/lib/features/onboarding/paywall_page.dart`
- [ ] T042 [US2] Classificar erros transitórios e falhas de vínculo da Google Play no BFF em `bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionValidationService.java`
- [ ] T043 [US2] Registrar auditoria mascarada das falhas, cancelamentos e tentativas repetidas em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/SubscriptionObservability.java`

**Checkpoint**: Fluxos cancelados, pendentes ou interrompidos não concedem Premium e podem ser retomados quando aplicável.

---

## Fase 5: História de Usuário 3 — Restauração após reinstalação ou troca de aparelho (P2)

**Objetivo**: Usuário autenticado recupera compra ativa por consulta de compras existentes e validação idempotente no BFF.

**Teste independente**: Simular aplicativo recém-instalado com compra ativa retornada pelo Billing e confirmar restauração sem nova assinatura.

### Testes da História 3

- [ ] T044 [P] [US3] Criar testes unitários de restauração e deduplicação de tokens em `bff/src/test/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionRestoreServiceTest.java`
- [ ] T045 [P] [US3] Criar teste de contrato para `POST /subscriptions/restore` em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SubscriptionRestoreControllerContractTest.java`
- [ ] T046 [P] [US3] Criar testes do app para recuperação no início e retorno ao foreground em `app/test/unit/services/subscription/subscription_restore_test.dart`

### Implementação da História 3

- [ ] T047 [US3] Consultar compras existentes no início e retorno ao foreground no adapter em `app/lib/services/subscription/google_play_billing_adapter.dart`
- [ ] T048 [US3] Implementar caso de uso idempotente de restauração no BFF em `bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionRestoreService.java`
- [ ] T049 [US3] Adicionar endpoint autenticado de restauração no controller em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SubscriptionController.java`
- [ ] T050 [US3] Implementar envio de compras restauradas e reconciliação do cache local em `app/lib/services/subscription/subscription_service.dart`
- [ ] T051 [US3] Integrar a ação de restaurar compras e suas mensagens no paywall em `app/lib/features/onboarding/paywall_page.dart`

**Checkpoint**: Reinstalação ou troca de aparelho recupera Premium ativo sem duplicação.

---

## Fase 6: História de Usuário 4 — Renovação automática e manutenção do acesso (P2)

**Objetivo**: BFF processa RTDN de modo idempotente, consulta o estado autoritativo e reconcilia em até uma hora.

**Teste independente**: Com fixtures, entregar RTDN duplicado ou fora de ordem para cada estado de ciclo de vida e confirmar entitlement correto, auditoria e cursor de reconciliação.

### Testes da História 4

- [ ] T052 [P] [US4] Criar testes da sincronização de estados, eventos duplicados e fora de ordem em `bff/src/test/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionLifecycleSyncServiceTest.java`
- [ ] T053 [P] [US4] Criar teste de integração do webhook RTDN e resposta idempotente em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/GooglePlayRtdnControllerIT.java`
- [ ] T054 [P] [US4] Criar testes do job de reconciliação, paginação e cursor em `bff/src/test/java/br/com/nutrity/vfpsolution/infrastructure/subscription/SubscriptionReconciliationJobTest.java`

### Implementação da História 4

- [ ] T055 [US4] Implementar mapeamento autoritativo de estados e atualização de entitlement em `bff/src/main/java/br/com/nutrity/vfpsolution/application/subscription/SubscriptionLifecycleSyncService.java`
- [ ] T056 [US4] Implementar adaptador/consumer RTDN com validação de origem e deduplicação em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/googleplay/GooglePlayRtdnConsumer.java`
- [ ] T057 [US4] Expor receptor de RTDN que delega sem expor tokens em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/GooglePlayRtdnController.java`
- [ ] T058 [US4] Implementar reconciliação horária, compras anuladas, paginação e atualização de cursor em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/subscription/SubscriptionReconciliationJob.java`
- [ ] T059 [US4] Publicar métricas de processamento, atraso, falha e divergência corrigida em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/SubscriptionObservability.java`

**Checkpoint**: Renovação, cancelamento, período de graça, suspensão, recuperação, expiração, reembolso e revogação atualizam acesso corretamente.

---

## Fase 7: História de Usuário 5 — Status e gerenciamento da assinatura (P3)

**Objetivo**: Perfil exibe plano e status atual, datas disponíveis e abre gerenciamento oficial da Google Play.

**Teste independente**: Com resumo de assinatura do BFF, abrir perfil Premium e confirmar status, data e redirecionamento em no máximo dois toques.

### Testes da História 5

- [ ] T060 [P] [US5] Criar teste de contrato para `GET /subscriptions/me` em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SubscriptionStatusControllerContractTest.java`
- [ ] T061 [P] [US5] Criar widget tests de status, cancelamento vigente, pendência e gerenciamento em `app/test/widget/features/home/profile_subscription_status_test.dart`

### Implementação da História 5

- [ ] T062 [US5] Expor resumo autenticado do plano efetivo em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SubscriptionController.java`
- [ ] T063 [US5] Consultar e persistir somente o resumo visual da assinatura em `app/lib/services/subscription/subscription_service.dart`
- [ ] T064 [US5] Criar ação de abertura do gerenciamento oficial da assinatura em `app/lib/services/subscription/google_play_subscription_management.dart`
- [ ] T065 [US5] Exibir plano, estado, próxima cobrança/término e gerenciamento acessível no perfil em `app/lib/features/home/profile_insights_page.dart`

**Checkpoint**: Usuário Premium consulta o estado atual e gerencia sua assinatura pela Google Play.

---

## Fase 8: Polimento e validação transversal

**Objetivo**: Garantir segurança, acessibilidade, documentação e qualidade ponta a ponta.

- [ ] T066 [P] Revisar traduções e mensagens acessíveis dos novos estados em `app/lib/l10n/app_localizations.dart`
- [ ] T067 [P] Revisar rate limiting e resposta de erro segura dos endpoints de assinatura em `bff/src/main/java/br/com/nutrity/vfpsolution/config/security/AppApiKeyFilter.java`
- [ ] T068 [P] Adicionar health indicator para dependência da Google Play e RTDN em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/GooglePlaySubscriptionHealthIndicator.java`
- [ ] T069 Executar `dart format`, `flutter analyze` e `flutter test` conforme `app/pubspec.yaml`
- [ ] T070 Executar `./mvnw test` conforme `bff/pom.xml`
- [ ] T071 Executar cenários manuais do ambiente de testes da Google Play em `specs/005-assinatura-premium-google-play/quickstart.md`
- [ ] T072 Atualizar evidências, riscos e decisões de implementação em `specs/005-assinatura-premium-google-play/plan.md`

---

## Dependências e ordem de execução

### Dependências por fase

- **Fase 1**: sem dependências.
- **Fase 2**: depende da Fase 1 e bloqueia todas as histórias.
- **US1 e US2**: iniciam após a Fase 2; US2 integra o fluxo criado em US1.
- **US3**: depende dos contratos e adaptadores da US1.
- **US4**: depende do modelo/persistência da Fase 2 e gateway da US1.
- **US5**: depende do resumo de assinatura e pode iniciar após US1; é recomendado após US4 para cobrir todos os estados.
- **Fase 8**: depende das histórias desejadas concluídas.

### Ordem recomendada

`Preparação → Fundação → US1 (MVP) → US2 → US3 + US4 → US5 → Polimento`

## Oportunidades de paralelismo

- T002–T006 podem ocorrer em paralelo.
- T008–T011 e T014–T016 podem ocorrer em paralelo após T007.
- Testes T019–T021 podem ocorrer em paralelo com os contratos correspondentes.
- Em US1, T022–T025 podem ser escritos em paralelo antes de T026–T035.
- US3 e US4 podem ser divididas entre integrantes após US1, pois usam arquivos majoritariamente distintos.
- T060–T061 podem ser paralelas; T066–T068 também.

## Estratégia de implementação

### MVP

Concluir Fases 1 e 2, depois a US1. Validar com compra de teste que somente a resposta do BFF concede Premium. Não iniciar RTDN, restauração completa ou tela de perfil antes desse checkpoint.

### Entregas incrementais

1. **US1**: contratação segura e validada.
2. **US2**: erros, pendência e cancelamento sem acesso indevido.
3. **US3**: restauração confiável.
4. **US4**: manutenção automática do entitlement.
5. **US5**: transparência e gerenciamento pelo usuário.

## Validação de formato

Todas as 72 tarefas usam checkbox, ID sequencial, marcador `[P]` apenas quando paralelo, marcador de história nas fases correspondentes e caminho de arquivo explícito.
