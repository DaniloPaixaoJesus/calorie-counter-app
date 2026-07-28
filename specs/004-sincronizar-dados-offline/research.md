# Pesquisa: Sincronização de Dados Online e Offline

## 1. Unidade e protocolo de sincronização

**Decisão**: usar um endpoint bidirecional em lotes, com até 100 mutações por requisição, cursor opaco para mudanças remotas e paginação.

**Justificativa**: reduz chamadas, atende uso offline e permite retomar bootstrap de até 1.000 registros sem bloquear a interface.

**Alternativas consideradas**:

- CRUD individual com consulta por data: mais simples por endpoint, mas pior para retries, tombstones e rate limit.
- Substituição integral do histórico: aumenta tráfego e risco de perda.

## 2. Idempotência

**Decisão**: cada mutação recebe `operationId` UUID estável; o BFF persiste o resultado por usuário e retorna o mesmo resultado em repetições.

**Justificativa**: uma resposta perdida não pode produzir duplicação ou reaplicar alteração.

**Alternativas consideradas**:

- Idempotência apenas pelo ID da entidade: não distingue atualizações sucessivas.
- Idempotência apenas pelo lote: impede retry parcial seguro.

## 3. Persistência local e outbox

**Decisão**: SQLite continua como fonte de verdade e recebe uma outbox transacional separada. Toda mutação de refeição/meta e sua operação pendente são gravadas na mesma transação.

**Justificativa**: garante uso offline e elimina a janela entre salvar o dado e registrar a intenção de sincronizar.

**Alternativas consideradas**:

- Chamar o BFF diretamente após cada CRUD: perde alterações em falhas e já falha para update/delete.
- Colocar flags de sync apenas na entidade: dificulta representar várias alterações e retries idempotentes.

## 4. Remoções

**Decisão**: representar remoções por tombstones locais e remotos, transmitidos no feed de mudanças. A limpeza física fica fora do caminho crítico e só ocorre após retenção definida operacionalmente.

**Justificativa**: dispositivos offline precisam receber a remoção e não podem ressuscitar uma versão antiga.

**Alternativas consideradas**:

- Hard delete imediato: impossibilita propagar a exclusão.
- Lista separada não relacionada às entidades: aumenta risco de inconsistência.

## 5. Resolução de conflitos

**Decisão**: na integração inicial, a versão remota vence para a mesma identidade. Depois, vence o maior `modifiedAt`, registrado no dispositivo e normalizado em UTC. Empates exatos usam `operationId` em ordem lexical como desempate determinístico.

**Justificativa**: implementa as clarificações da spec e mantém convergência em todos os dispositivos.

**Alternativas consideradas**:

- Versão remota sempre vence: rejeitada pelo usuário para conflitos posteriores.
- Escolha manual: aumenta complexidade e interrompe a sincronização.
- Merge por campo: não é seguro para todos os campos e remoções.

**Risco aceito**: relógio incorreto do dispositivo pode tornar uma alteração artificialmente recente. O app deve registrar UTC e testes devem cobrir skew; correção automática do relógio não foi autorizada pela spec.

## 6. Identidade e isolamento

**Decisão**: UUID da entidade permanece estável; no BFF a chave de negócio inclui usuário, tipo e ID da entidade. O usuário é obtido do token validado, nunca aceito do payload.

**Justificativa**: impede colisão global e acesso cruzado entre contas.

**Alternativas consideradas**:

- PK global atual da refeição: um ID repetido pode atingir dado de outra conta.
- Deduplicação por conteúdo: contradiz a spec.

## 7. Meta nutricional do MVP

**Decisão**: modelar a meta calórica diária atual como uma entidade sincronizável com ID canônico `daily-calorie`, valor entre 800 e 6.000 kcal/dia, vigência e `modifiedAt`.

**Justificativa**: satisfaz “refeições e metas nutricionais” reutilizando o único objetivo existente, sem criar metas de macronutrientes não solicitadas.

**Alternativas consideradas**:

- Sincronizar todo o perfil: está fora do escopo.
- Criar metas de proteína, carboidrato e gordura: expansão de produto sem requisitos.

## 8. Premium e IA

**Decisão**: o BFF é a autoridade do premium. Sync retorna `403 PREMIUM_REQUIRED` quando inativo; o app pausa envio e preserva pendências. A IA consulta o premium ativo da conta autenticada; token válido sem premium segue política free.

**Justificativa**: hoje o BFF marca todo login Google como premium e a IA considera qualquer bearer premium, contrariando RF-025/RF-026.

**Alternativas consideradas**:

- Confiar no booleano local: manipulável e sujeito a desatualização.
- Fazer logout na expiração: rejeitado na clarificação.

## 9. Gatilhos e retries

**Decisão**: sincronizar após login premium, retorno ao foreground, mutação local, renovação e retry manual. Falhas temporárias usam backoff limitado enquanto o app está ativo; não será adicionada execução contínua em background no MVP.

**Justificativa**: minimiza dependências e consumo de bateria; uma checagem de conectividade não garante que o BFF esteja alcançável.

**Alternativas consideradas**:

- Plugin de conectividade: pode ser avaliado depois, mas não substitui tratamento de falhas reais.
- Worker permanente: complexidade operacional desnecessária para o MVP.

## 10. Logout seguro

**Decisão**: tentar sync antes de revogar a sessão; se restarem pendências, exigir confirmação. Ao confirmar, gravar `cleanupPending`, limpar dados da conta/outbox/cursor/sessão em transação e só então concluir a UI. O bootstrap termina a limpeza interrompida antes de exibir dados.

**Justificativa**: atende privacidade e tolera encerramento do app durante logout.

**Alternativas consideradas**:

- Desconectar Google primeiro: pode impedir o último envio.
- Apagar tabelas fora de transação: pode expor estado parcial após crash.

## 11. Banco remoto e migrações

**Decisão**: usar PostgreSQL em produção com migrações versionadas; manter H2 apenas em testes compatíveis. Desabilitar geração automática destrutiva de schema fora do ambiente local.

**Justificativa**: o H2 em memória atual perde o histórico e `ddl-auto=update` não atende governança de mudanças.

**Alternativas consideradas**:

- Persistir H2 em arquivo: inadequado para múltiplas instâncias e operação em nuvem.
- Novo serviço NoSQL: não há necessidade que justifique outra tecnologia.

## 12. Segurança e observabilidade

**Decisão**: remover segredo padrão embarcado, exigir configuração externa, validar API key e bearer, ownership, premium, tamanho do lote e payload. Registrar correlation ID, usuário pseudonimizado, contagens, cursor, resultado e latência, nunca conteúdo, email ou token.

**Justificativa**: atende a constituição e permite diagnosticar auth, persistência e sincronização.

**Alternativas consideradas**:

- Manter API key no binário: não é segredo efetivo e viola a política do projeto.
- Logar payload para diagnóstico: risco desnecessário de privacidade.
