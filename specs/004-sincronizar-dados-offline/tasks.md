# Tarefas: Sincronização de Dados Online e Offline

**Entrada**: Artefatos de design em `specs/004-sincronizar-dados-offline/`

**Pré-requisitos**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Testes**: Obrigatórios conforme a constituição. Em cada história, escrever os testes indicados e confirmar que falham antes da implementação correspondente.

**Organização**: As tarefas estão agrupadas por história de usuário para permitir implementação e validação incrementais.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: Pode executar em paralelo por atuar em arquivo independente e não depender de tarefa incompleta.
- **[Story]**: História atendida (`US1`, `US2` ou `US3`).

## Fase 1: Setup

**Objetivo**: Preparar dependências, configuração e estrutura mínima compartilhada.

- [X] T001 Adicionar Flyway e driver PostgreSQL de runtime, preservando H2 para testes, em `bff/pom.xml`
- [X] T002 [P] Separar configurações de banco local, teste e produção e desabilitar atualização automática de schema fora do ambiente local em `bff/src/main/resources/application.yml`
- [X] T003 [P] Remover o valor padrão da API key e exigir configuração externa em `app/lib/services/bff/bff_client.dart`
- [X] T004 [P] Criar o barrel inicial da feature de sincronização em `app/lib/features/sync/sync.dart`
- [X] T005 [P] Registrar códigos e mensagens localizadas dos estados de sincronização em `app/lib/l10n/app_localizations.dart`

---

## Fase 2: Fundamentos Bloqueantes

**Objetivo**: Criar contratos, modelos e persistência compartilhados por todas as histórias.

**⚠️ CRÍTICO**: Nenhuma história deve ser integrada antes da conclusão desta fase.

### Testes fundamentais

- [X] T006 [P] Criar testes unitários das regras de identidade, datas UTC, tombstones, LWW e desempate por `operationId` em `app/test/unit/sync_domain_test.dart`
- [ ] T007 [P] Criar teste de migração SQLite da versão 3 preservando refeições e configurações existentes em `app/test/integration/app_database_migration_test.dart`
- [X] T008 [P] Criar testes JPA das chaves por usuário, tombstones, sequência e unicidade de operações em `bff/src/test/java/br/com/nutrity/vfpsolution/infrastructure/persistence/SyncPersistenceTest.java`

### Implementação fundamental no app

- [X] T009 [P] Criar os enums e modelos puros `SyncEntityType`, `SyncOperationType`, `SyncOperationStatus` e `SyncState` em `app/lib/features/sync/domain/sync_types.dart`
- [X] T010 [P] Criar as entidades puras `SyncOperation`, `SyncCheckpoint` e `RemoteChange` em `app/lib/features/sync/domain/sync_models.dart`
- [X] T011 [P] Criar a entidade `NutritionGoal` para a meta calórica diária canônica em `app/lib/features/sync/domain/nutrition_goal.dart`
- [X] T012 Adicionar `modifiedAt`, `deletedAt` e `ownerUserId` sem misturar `timestamp` da refeição em `app/lib/models/meal.dart`
- [X] T013 Definir contratos substituíveis para storage transacional, outbox, checkpoint, sessão, relógio e gateway remoto em `app/lib/features/sync/domain/sync_ports.dart`
- [X] T014 Centralizar abertura e versionamento do SQLite, incluindo tabelas de refeições, metas, outbox, checkpoint e controle de limpeza em `app/lib/services/repository/app_database.dart`
- [X] T015 Implementar a migração SQLite versionada a partir da versão 3, preenchendo `modifiedAt` sem perder registros existentes, em `app/lib/services/repository/app_database.dart`
- [X] T016 Implementar o adapter transacional de dados sincronizáveis e outbox em `app/lib/features/sync/infrastructure/sqlite_sync_store.dart`
- [X] T017 [P] Implementar o adapter em memória equivalente para testes e plataformas sem SQLite em `app/lib/features/sync/infrastructure/in_memory_sync_store.dart`

### Implementação fundamental no BFF

- [X] T018 Criar a migração inicial versionada para usuários/refeições existentes e novas tabelas de metas, mudanças e operações processadas em `bff/src/main/resources/db/migration/V1__baseline_and_sync.sql`
- [X] T019 [P] Adicionar metadados de sincronização e ownership seguro à entidade de refeição em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/entity/UserMeal.java`
- [X] T020 [P] Criar entidades JPA `NutritionGoal`, `SyncChange` e `ProcessedSyncOperation` em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/persistence/sync/`
- [X] T021 Criar repositórios de metas, feed de mudanças e idempotência em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/persistence/sync/`
- [X] T022 Definir DTOs validados de request/response conforme OpenAPI, com limite de 100 mutações, em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/sync/`
- [X] T023 Criar serviço de autorização que derive usuário do token, valide ownership e premium ativo em `bff/src/main/java/br/com/nutrity/vfpsolution/application/sync/SyncAuthorizationService.java`
- [X] T024 Padronizar `ApiError` com `code`, mensagem segura e correlation ID para sync em `bff/src/main/java/br/com/nutrity/vfpsolution/application/exceptionhandler/ApiExceptionHandler.java`

**Checkpoint**: Modelos, contratos internos, migrações e segurança base estão disponíveis.

---

## Fase 3: História de Usuário 1 — Integrar dados locais ao entrar (P1) 🎯 MVP

**Objetivo**: Após login premium, unir refeições e meta calórica locais/remotas sem duplicação, mantendo o app utilizável durante o bootstrap.

**Teste independente**: Criar registros anônimos e remotos, autenticar uma conta premium e comprovar união completa, remote-wins para IDs conflitantes, retomada após interrupção e ausência de duplicação em três repetições.

### Testes da História 1

- [X] T025 [P] [US1] Criar teste de contrato do `POST /users/{userId}/sync` para bootstrap, paginação, validação, auth e ownership em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SyncControllerContractTest.java`
- [X] T026 [P] [US1] Criar testes unitários de bootstrap remote-wins, associação de dados anônimos e cursor reiniciável em `app/test/unit/sync_bootstrap_test.dart`
- [ ] T027 [P] [US1] Criar teste de integração SQLite para união transacional de refeições e meta calórica em `app/test/integration/sync_bootstrap_sqlite_test.dart`
- [ ] T028 [P] [US1] Criar widget test de login não bloqueante e estados sincronizando/atualizado/erro em `app/test/widget/sync_login_flow_test.dart`
- [ ] T029 [P] [US1] Criar teste de serviço BFF para bootstrap, idempotência por operação e isolamento entre contas em `bff/src/test/java/br/com/nutrity/vfpsolution/domain/service/sync/SyncServiceBootstrapTest.java`

### Implementação da História 1

- [X] T030 [P] [US1] Implementar DTOs remotos Dart separados dos modelos locais e serialização do contrato batch em `app/lib/features/sync/infrastructure/sync_dto.dart`
- [X] T031 [P] [US1] Implementar o gateway HTTP de sync, paginação, erros tipados e correlation ID em `app/lib/features/sync/infrastructure/bff_sync_gateway.dart`
- [X] T032 [US1] Implementar processamento idempotente, regra remote-wins do bootstrap e feed paginado no BFF em `bff/src/main/java/br/com/nutrity/vfpsolution/application/sync/SyncService.java`
- [X] T033 [US1] Expor `POST /users/{userId}/sync` conforme `contracts/openapi.yaml` em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SyncController.java`
- [X] T034 [US1] Implementar o `SyncCoordinator` com bootstrap paginado, aplicação transacional, cursor e retomada em `app/lib/features/sync/application/sync_coordinator.dart`
- [X] T035 [US1] Associar refeições e meta anônimas à conta somente após confirmação do bootstrap em `app/lib/features/sync/application/sync_coordinator.dart`
- [X] T036 [US1] Disparar bootstrap não bloqueante após autenticação Google premium em `app/lib/services/subscription/subscription_service.dart`
- [X] T037 [US1] Registrar gateway, store, relógio e coordenador no Provider sem mover regras para widgets em `app/lib/main.dart`
- [X] T038 [US1] Expor estado do coordenador e ação de retry manual em `app/lib/features/sync/presentation/sync_view_model.dart`
- [X] T039 [US1] Exibir indicador acessível de sincronização sem bloquear CRUD em `app/lib/features/home/home_shell_page.dart`
- [ ] T040 [US1] Executar os cenários de bootstrap e isolamento do quickstart e registrar evidências em `specs/004-sincronizar-dados-offline/quickstart.md`

**Checkpoint**: A História 1 funciona como MVP e pode ser demonstrada sem depender das histórias 2 e 3.

---

## Fase 4: História de Usuário 2 — Continuar usando offline (P2)

**Objetivo**: Manter CRUD local offline, enfileirar inclusões/edições/remoções e metas, convergir por LWW após reconexão e pausar/retomar conforme premium.

**Teste independente**: Desativar a rede, criar/editar/remover refeições e alterar a meta, reiniciar o app, reconectar e confirmar envio único, conflitos LWW, tombstones e pausa/retomada do premium.

### Testes da História 2

- [X] T041 [P] [US2] Criar testes unitários de outbox transacional para create/update/delete/meta e recuperação de `sending` em `app/test/unit/sync_outbox_test.dart`
- [ ] T042 [P] [US2] Criar testes unitários do coordenador para timeout, backoff, 401, 403, 409, 413, 429 e 5xx em `app/test/unit/sync_retry_policy_test.dart`
- [X] T043 [P] [US2] Criar testes BFF de LWW, empate por `operationId`, delete versus update e replay idempotente em `bff/src/test/java/br/com/nutrity/vfpsolution/domain/service/sync/SyncServiceConflictTest.java`
- [ ] T044 [P] [US2] Criar teste de integração offline/restart/reconexão usando SQLite e gateway fake em `app/test/integration/offline_sync_test.dart`
- [ ] T045 [P] [US2] Criar widget test dos estados pendente, pausado sem premium, autenticação necessária e falha recuperável em `app/test/widget/sync_status_test.dart`
- [X] T046 [P] [US2] Criar teste do BFF garantindo que token válido com premium inativo usa política free de IA em `bff/src/test/java/br/com/nutrity/vfpsolution/domain/service/ai/MealEstimatePremiumPolicyTest.java`

### Implementação da História 2

- [X] T047 [US2] Adaptar add/update/remove de refeições para gravar entidade e outbox na mesma transação em `app/lib/services/repository/sqlite_meal_repository.dart`
- [X] T048 [US2] Tornar a atualização da meta calórica local-first e enfileirar sua mutação em `app/lib/services/subscription/subscription_service.dart`
- [X] T049 [US2] Implementar LWW pós-bootstrap, tombstones e desempate determinístico no BFF em `bff/src/main/java/br/com/nutrity/vfpsolution/application/sync/SyncService.java`
- [X] T050 [US2] Implementar processamento de ack, mudança canônica, paginação completa e compactação segura da outbox em `app/lib/features/sync/application/sync_coordinator.dart`
- [X] T051 [US2] Implementar gatilhos em mutação, retorno ao foreground, renovação e retry manual com backoff limitado em `app/lib/features/sync/application/sync_trigger_service.dart`
- [X] T052 [US2] Pausar envios em premium inativo e preservar/criar pendências até a renovação em `app/lib/features/sync/application/sync_coordinator.dart`
- [X] T053 [US2] Fazer o BFF consultar premium ativo da conta antes de selecionar a política de IA em `bff/src/main/java/br/com/nutrity/vfpsolution/domain/service/ai/MealEstimateService.java`
- [X] T054 [US2] Não enviar bearer premium à IA quando a assinatura local estiver inativa em `app/lib/services/ai_adapter/bff_ai_adapter.dart`
- [X] T055 [US2] Conectar o status textual/semântico e retry manual às telas conforme `contracts/sync-ui.md` em `app/lib/features/sync/presentation/sync_status_widget.dart`
- [ ] T056 [US2] Executar os cenários offline, conflitos, volume e expiração/renovação e registrar evidências em `specs/004-sincronizar-dados-offline/quickstart.md`

**Checkpoint**: As Histórias 1 e 2 convergem online e continuam funcionais offline de forma independente.

---

## Fase 5: História de Usuário 3 — Proteger dados ao sair (P3)

**Objetivo**: Tentar sincronizar antes do logout, avisar sobre pendências e remover de forma transacional e reiniciável todos os dados da conta no dispositivo.

**Teste independente**: Entrar, carregar dados, criar pendências online e offline, confirmar logout e verificar após reinício que refeições, meta, outbox, cursor, token e sessão foram removidos.

### Testes da História 3

- [X] T057 [P] [US3] Criar testes unitários do caso de uso de logout para flush bem-sucedido, cancelamento e confirmação com pendências em `app/test/unit/sync_logout_test.dart`
- [ ] T058 [P] [US3] Criar teste de integração SQLite para limpeza atômica e retomada por `cleanupPending` após interrupção em `app/test/integration/logout_cleanup_test.dart`
- [X] T059 [P] [US3] Criar widget test do diálogo acessível com contagem, “Continuar no app” e “Sair e apagar” em `app/test/widget/logout_pending_sync_dialog_test.dart`

### Implementação da História 3

- [X] T060 [US3] Implementar caso de uso de logout com sync best-effort antes de revogar a sessão em `app/lib/features/sync/application/logout_coordinator.dart`
- [X] T061 [US3] Implementar marcação `cleanupPending` e limpeza transacional de refeições, meta, outbox, cursor, token e sessão em `app/lib/features/sync/infrastructure/sqlite_sync_store.dart`
- [X] T062 [US3] Finalizar limpeza interrompida antes de construir a UI e carregar repositórios em `app/lib/main.dart`
- [X] T063 [US3] Integrar confirmação/cancelamento e desconexão Google posterior à limpeza no fluxo de perfil em `app/lib/features/home/profile_insights_page.dart`
- [X] T064 [US3] Criar diálogo Material 3 acessível conforme contrato de UX em `app/lib/features/sync/presentation/pending_logout_dialog.dart`
- [X] T065 [US3] Garantir que o primeiro uso anônimo após logout inicia com banco funcional vazio em `app/lib/services/subscription/subscription_service.dart`
- [ ] T066 [US3] Executar o cenário de logout interrompido e registrar evidências em `specs/004-sincronizar-dados-offline/quickstart.md`

**Checkpoint**: Todas as histórias estão implementadas e testáveis de forma independente.

---

## Fase 6: Polimento e Aspectos Transversais

**Objetivo**: Validar segurança, observabilidade, desempenho, contratos e portões finais.

- [X] T067 [P] Adicionar logs estruturados e métricas de resultado/latência sem payload pessoal em `bff/src/main/java/br/com/nutrity/vfpsolution/infrastructure/observability/SyncObservability.java`
- [X] T068 [P] Adicionar diagnóstico técnico local sem conteúdo de refeição, email ou token em `app/lib/features/sync/infrastructure/sync_diagnostics.dart`
- [X] T069 Endurecer limites, rate limiting, ownership e mensagens seguras do endpoint em `bff/src/main/java/br/com/nutrity/vfpsolution/application/api/SyncController.java`
- [X] T070 [P] Criar teste de compatibilidade do adapter Dart com exemplos do OpenAPI em `app/test/unit/sync_contract_compliance_test.dart`
- [X] T071 [P] Criar teste de compatibilidade do controller BFF com `contracts/openapi.yaml` em `bff/src/test/java/br/com/nutrity/vfpsolution/application/api/SyncOpenApiComplianceTest.java`
- [X] T072 Executar `dart format`, `flutter analyze` e toda a suíte Flutter a partir de `app/`
- [X] T073 Executar `./mvnw test` e toda a suíte de contrato/persistência a partir de `bff/`
- [ ] T074 Validar manualmente todos os critérios CS-001 a CS-007 e atualizar os resultados em `specs/004-sincronizar-dados-offline/quickstart.md`

---

## Dependências e Ordem de Execução

### Dependências entre fases

- **Fase 1 — Setup**: início imediato.
- **Fase 2 — Fundamentos**: depende da Fase 1 e bloqueia todas as histórias.
- **Fase 3 — US1**: depende da Fase 2; é o MVP.
- **Fase 4 — US2**: depende da Fase 2 para desenvolvimento isolado e integra-se ao endpoint entregue na US1.
- **Fase 5 — US3**: depende da Fase 2 para desenvolvimento isolado; a tentativa de flush usa o coordenador da US1/US2 na integração final.
- **Fase 6 — Polimento**: depende das histórias escolhidas para a entrega.

### Dependências entre histórias

```text
Setup → Fundamentos → US1 (MVP)
                   ├→ US2
                   └→ US3

US1 + US2 + US3 → Polimento
```

- **US1** não depende de outra história e entrega bootstrap bidirecional.
- **US2** pode ser desenvolvida após os fundamentos com gateway fake; a validação ponta a ponta depende do endpoint da US1.
- **US3** pode ser desenvolvida após os fundamentos com coordenador fake; o flush real integra com US1/US2.

### Ordem interna

1. Escrever os testes da fase e confirmar falha pelo motivo esperado.
2. Implementar modelos e persistência.
3. Implementar serviços/casos de uso.
4. Implementar endpoint ou integração.
5. Integrar apresentação.
6. Executar o teste independente e registrar evidências.

## Oportunidades de Paralelismo

### História 1

```text
T025 contrato BFF ─┐
T026 domínio app ──┼─→ T032–T039 integração
T027 SQLite app ───┤
T028 widget app ───┤
T029 serviço BFF ──┘

T030 DTO Dart ─────┐
T031 gateway HTTP ─┴─→ T034 coordenador
```

### História 2

```text
T041 outbox ───────┐
T042 retries ──────┤
T043 conflitos BFF ┼─→ T047–T055 implementação
T044 integração ───┤
T045 widget ───────┤
T046 IA/premium ───┘
```

### História 3

```text
T057 logout unitário ─┐
T058 limpeza SQLite ──┼─→ T060–T065 implementação
T059 diálogo widget ──┘
```

## Estratégia de Implementação

### MVP primeiro

1. Concluir Setup.
2. Concluir Fundamentos.
3. Implementar US1.
4. Parar e validar bootstrap, idempotência, remote-wins e uso não bloqueante.
5. Demonstrar o MVP antes de ampliar retries, expiração e logout.

### Entrega incremental

1. **US1**: continuidade do histórico após login premium.
2. **US2**: robustez offline, conflitos, tombstones e premium pausado.
3. **US3**: privacidade e limpeza segura no logout.
4. **Polimento**: segurança, telemetria, desempenho e portões.

## Notas

- Tarefas `[P]` atuam em arquivos independentes no ponto em que aparecem.
- IDs são sequenciais e as tarefas de histórias possuem o rótulo correspondente.
- Não usar rede, relógio ou serviços pagos reais na suíte automatizada padrão.
- Commits devem agrupar tarefas relacionadas e manter o app/BFF compatíveis com o contrato.
