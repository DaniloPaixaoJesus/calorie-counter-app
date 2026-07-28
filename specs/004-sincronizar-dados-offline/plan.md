# Plano de Implementação: Sincronização de Dados Online e Offline

**Branch**: `main` | **Data**: 2026-07-27 | **Spec**: [spec.md](spec.md)

**Entrada**: Especificação em `specs/004-sincronizar-dados-offline/spec.md`

## Resumo

Implementar sincronização bidirecional de refeições e da meta calórica diária para contas Google com premium ativo, preservando SQLite como fonte local de verdade e o uso integral do app offline. O app registrará alterações em uma outbox persistente, e um coordenador de sincronização enviará lotes idempotentes ao BFF e aplicará mudanças remotas por cursor. Remoções serão representadas por tombstones; a integração inicial dará precedência ao remoto para identidades coincidentes e conflitos posteriores usarão a data de modificação registrada no dispositivo. Logout fará tentativa de envio, confirmação quando houver pendências e limpeza transacional reiniciável.

## Contexto Técnico

**Linguagens/versões**: Dart >=3.0.0 <4.0.0 com Flutter; Java 21 com Spring Boot 3.3.4

**Dependências principais**: Flutter, Provider/ChangeNotifier, sqflite, google_sign_in; Spring Web, Security, Validation, Data JPA e Actuator

**Persistência**: SQLite no app; PostgreSQL persistente no BFF em produção, H2 isolado para testes; migrações versionadas em ambos

**Testes**: flutter_test, testes unitários/widget/integração SQLite no app; JUnit/Spring Boot Test e testes de contrato/persistência no BFF

**Plataformas-alvo**: Android e iOS para persistência/sincronização; BFF HTTP conteinerizado

**Tipo de projeto**: Monorepo com aplicativo mobile e serviço BFF

**Metas de desempenho**: uso local imediato; 95% das sincronizações de até 100 pendências concluídas em até 30 segundos; bootstrap de até 1.000 itens paginado sem bloquear a UI

**Restrições**: offline-first; SQLite é fonte local de verdade; premium obrigatório para tráfego de sincronização; dados de contas isolados; datas de alteração em UTC com offset original aceito; sem payload pessoal em logs; operações repetíveis sem duplicação

**Escala/escopo**: refeições e uma meta calórica diária por usuário no MVP; lotes de até 100 mutações; até 1.000 registros locais e 1.000 remotos nos cenários de validação

## Verificação da Constituição

*GATE: verificado antes da pesquisa e novamente após o design.*

| Princípio | Status | Evidência no plano |
|---|---|---|
| I. Idioma | PASS | Todos os artefatos desta feature estão em português do Brasil |
| II. Simplicidade | PASS | Um endpoint batch, uma outbox e os repositórios existentes; sem novo gerenciador de estado nem worker de background obrigatório |
| III. Offline First | PASS | CRUD grava primeiro no SQLite; rede nunca bloqueia operações locais |
| IV. Arquitetura e dependências | PASS | Coordenador depende de contratos internos; DTOs HTTP e persistência ficam em adapters |
| V. Material 3, acessibilidade e experiência | PASS | Estados de sync e diálogo de logout usam componentes existentes, sem depender apenas de cor |
| VI. Dados, persistência e sincronização | PASS | Identidade, idempotência, LWW, tombstones, UTC, cursor e migrações estão definidos |
| VII. Testes por risco | PASS | Regras, migrações, contratos, falhas e fluxos visuais têm cobertura planejada |
| VIII. IA isolada e degradável | PASS | Elegibilidade da IA será derivada do premium ativo no BFF; premium inativo usa política free |
| IX. MVP Primeiro | PASS | Escopo restrito a refeições e meta calórica diária |
| X. Arquitetura Flutter e Dart | PASS | Provider/ChangeNotifier permanece; regras saem do ViewModel para aplicação/domínio |
| XI. Arquitetura do BFF e contratos de API | PASS | Controller apenas transporta; serviço aplica regras; OpenAPI versionado e escrita idempotente |
| XII. Segurança, privacidade e observabilidade | PASS | Bearer validado, ownership obrigatório, segredo sem default embarcado e telemetria sem payload |
| XIII. Portões de qualidade | PASS | `dart format`, `flutter analyze`, `flutter test`, `./mvnw test` e contrato ponta a ponta previstos |

**Resultado inicial**: PASS. Não há violação constitucional a justificar.

## Estrutura do Projeto

### Documentação desta funcionalidade

```text
specs/004-sincronizar-dados-offline/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── openapi.yaml
│   └── sync-ui.md
└── tasks.md
```

### Código-fonte

```text
app/
├── lib/
│   ├── features/sync/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── presentation/
│   ├── models/
│   ├── services/
│   │   ├── auth/
│   │   ├── bff/
│   │   ├── repository/
│   │   └── subscription/
│   └── main.dart
└── test/
    ├── unit/
    ├── integration/
    └── widget/

bff/
├── src/main/java/br/com/nutrity/vfpsolution/
│   ├── application/api/
│   ├── domain/
│   │   ├── dto/sync/
│   │   ├── entity/
│   │   ├── repository/
│   │   └── service/sync/
│   └── infrastructure/
├── src/main/resources/db/migration/
└── src/test/
```

**Decisão de estrutura**: manter o monorepo e as camadas existentes, introduzindo uma feature de sincronização no app e um serviço de aplicação dedicado no BFF. `HomeViewModel` e `SubscriptionService` apenas disparam casos de uso e observam estado; não executam protocolo, SQL ou resolução de conflito.

## Fase 0 — Pesquisa

As decisões, alternativas e riscos estão consolidados em [research.md](research.md). Todos os pontos técnicos necessários ao design foram resolvidos.

## Fase 1 — Design e Contratos

- [data-model.md](data-model.md): entidades locais/remotas, identidade, relacionamentos, invariantes e transições.
- [contracts/openapi.yaml](contracts/openapi.yaml): contrato HTTP do lote bidirecional, autenticação, idempotência, paginação e erros.
- [contracts/sync-ui.md](contracts/sync-ui.md): estados observáveis, login não bloqueante, premium pausado e confirmação de logout.
- [quickstart.md](quickstart.md): roteiro de validação ponta a ponta e portões de qualidade.

### Sequência de implementação proposta

1. Centralizar a abertura/versionamento do SQLite e criar migração preservando refeições e configurações atuais.
2. Introduzir metadados sincronizáveis, tombstones, outbox e estado de sessão/limpeza no app.
3. Criar modelos remotos separados e o `SyncCoordinator`, com relógio e gateway substituíveis.
4. Adicionar migrações persistentes, entidades, repositórios e serviço de sync no BFF.
5. Publicar o endpoint batch autenticado e validar premium/ownership em todas as operações.
6. Integrar login, retomada, mutações locais, retry manual, renovação/expiração e logout.
7. Corrigir a elegibilidade de IA para consultar premium ativo, e não apenas presença de token.
8. Expor estados acessíveis de sincronização e mensagens de recuperação.
9. Cobrir regras, migrações, contratos e fluxos de interrupção; validar ponta a ponta.

## Verificação Pós-Design da Constituição

| Área de risco | Status | Verificação |
|---|---|---|
| Offline e recuperação | PASS | Outbox e SQLite mantêm alterações antes de qualquer chamada remota |
| Identidade e idempotência | PASS | `(userId, entityType, entityId)` e `operationId` evitam colisão e repetição |
| Conflitos e datas | PASS | Bootstrap remote-wins; depois LWW por `modifiedAt` do dispositivo, em UTC, com desempate determinístico |
| Remoções | PASS | Tombstones propagam exclusões sem ressuscitar registros antigos |
| Migrações | PASS | SQLite e BFF usam migrações versionadas com testes de upgrade |
| Segurança e premium | PASS | Token identifica a conta; path não autoriza sozinho; premium ativo controla sync e IA |
| Privacidade e logs | PASS | Somente IDs técnicos, resultado, latência e correlação; nenhum conteúdo de refeição/token |
| UX e acessibilidade | PASS | Uso não bloqueante e estado textual/semântico para pendente, sincronizando, sucesso e erro |
| Testabilidade | PASS | Relógio, rede, storage e sessão possuem contratos substituíveis |

**Resultado pós-design**: PASS.

## Decisões de Dependência e Operação

| Decisão | Justificativa | Alternativa mais simples avaliada |
|---|---|---|
| Adicionar migrações versionadas no BFF | Dados remotos precisam sobreviver a releases com schema previsível | `ddl-auto=update` não fornece rollback, auditoria nem teste de migração |
| Usar PostgreSQL em produção | H2 em memória perde dados ao reiniciar e não atende persistência de conta | Manter H2 apenas para testes |
| Não adicionar detector de conectividade no MVP | Login, retorno ao foreground, mutações e retry manual já fornecem gatilhos suficientes | Plugin de conectividade adicionaria dependência sem garantir acesso real ao BFF |
| Não adotar biblioteca nova de estado | Provider/ChangeNotifier atual atende a exposição dos estados de sync | Uma nova biblioteca aumentaria migração sem benefício necessário |

## Rastreamento de Complexidade

Não há violações da constituição. PostgreSQL e migrações são necessidades diretas de persistência remota durável, registradas acima.
