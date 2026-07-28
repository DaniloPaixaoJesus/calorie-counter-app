# ADR-001: Persistência Remota e Migrações Versionadas

**Status**: Aceita

**Data**: 2026-07-27

## Contexto

O BFF atual usa H2 em memória e atualização automática de schema. A sincronização exige que refeições, meta calórica, tombstones, cursores e registros de idempotência sobrevivam a reinícios e possam evoluir sem perda.

## Decisão

Usar PostgreSQL como banco relacional persistente em produção e Flyway para todas as alterações de schema do BFF. H2 permanece somente em desenvolvimento e testes de compatibilidade. Em produção, a validação do schema substitui a criação ou alteração automática.

## Consequências

- O ambiente de produção precisa fornecer conexão PostgreSQL e credenciais por configuração externa.
- Toda mudança futura de schema exige migração versionada e teste.
- O deploy deve executar migrações antes de aceitar tráfego.
- A compatibilidade H2/PostgreSQL deve ser coberta por testes de persistência.

## Alternativas rejeitadas

- **H2 em arquivo**: não é adequado a múltiplas instâncias nem à operação gerenciada em nuvem.
- **`ddl-auto=update`**: não oferece histórico, revisão ou previsibilidade de rollout.
- **Novo banco NoSQL**: adicionaria tecnologia sem requisito que justifique a complexidade.
