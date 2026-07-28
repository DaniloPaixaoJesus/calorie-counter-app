# Especificação de Feature: Assinatura Premium e Integração com Google Play Billing

**Branch de Feature**: `005-assinatura-premium-google-play`

**Criado em**: 2026-07-28

**Status**: Rascunho

---

## Clarificações

### Sessão 2026-07-28

- P: Qual conta Google pode ser vinculada à compra? → R: A compra só pode ser vinculada se a conta Google autenticada for a mesma utilizada no pagamento.
- P: Como manter o status atualizado se uma notificação de ciclo de vida for perdida? → R: Atualizar por notificações em tempo real e reconciliar periodicamente todas as assinaturas ativas.
- P: Qual o intervalo máximo para a reconciliação periódica? → R: Até uma hora.
- P: Como tratar notificações de status atrasadas ou fora de ordem? → R: Validar o estado atual na Google Play antes de aplicar cada mudança de status.
- P: Como o usuário com assinatura ativa troca de plano? → R: Pelo gerenciamento da assinatura na Google Play; o aplicativo exibe o plano vigente e a ação de gerenciamento.
- P: Como comprovar o vínculo da compra com a conta Google diante da limitação da Google Play? → R: Exigir autenticação Google antes do pagamento.

---

## Cenários de Usuário e Testes *(obrigatório)*

### História de Usuário 1 — Contratação da assinatura Premium (Prioridade: P1)

O usuário Free (sem conta) acessa a tela de planos a partir do aplicativo e visualiza os planos Premium disponíveis com preço e periodicidade retornados pela Google Play. Ao selecionar um plano, ele autentica com uma conta Google; o BFF cria ou identifica sua conta. O usuário então conclui o pagamento pelo fluxo oficial da Google Play. O BFF valida a compra e o reconhece como Premium. As funcionalidades Premium são liberadas sem que o usuário precise realizar nenhuma etapa adicional.

**Por que esta prioridade**: É o fluxo central que habilita a receita da feature. Sem ele, nenhum outro cenário faz sentido.

**Teste independente**: Pode ser validado com um usuário sem conta acessando a tela de planos, autenticando com Google, realizando uma compra de teste pela Google Play e verificando que as funcionalidades Premium ficam disponíveis após a confirmação do BFF.

**Cenários de Aceite**:

1. **Dado** que o usuário não possui conta no Nutrity, **Quando** ele acessa a tela de planos, **Então** o aplicativo exibe os planos Premium disponíveis com preço, periodicidade e condições retornados pela Google Play.
2. **Dado** que o usuário visualiza os planos, **Quando** ele seleciona um plano e confirma a compra, **Então** o fluxo oficial de pagamento da Google Play é apresentado — e o aplicativo não solicita ou armazena dados de cartão.
3. **Dado** que o usuário seleciona um plano sem estar autenticado, **Quando** ele confirma a intenção de assinar, **Então** o aplicativo conduz o usuário para autenticar com uma conta Google antes de iniciar o pagamento.
4. **Dado** que o usuário autentica com Google, **Quando** o BFF cria ou identifica sua conta, **Então** o aplicativo inicia o pagamento associado à conta autenticada.
5. **Dado** que o usuário conclui o pagamento na Google Play, **Quando** o aplicativo envia os dados da compra e o token de autenticação ao BFF, **Então** o BFF valida a compra junto à Google Play, registra a assinatura e reconhece o usuário como Premium.
6. **Dado** que a assinatura é confirmada, **Quando** o aplicativo recebe a confirmação do BFF, **Então** as funcionalidades Premium são liberadas imediatamente, sem etapa adicional de login.
7. **Dado** que o usuário já possui uma assinatura ativa e tenta iniciar nova compra do mesmo plano, **Quando** o aplicativo detecta a assinatura vigente, **Então** impede o início e informa que a assinatura já está ativa.
8. **Dado** que os mesmos dados de compra são enviados mais de uma vez ao BFF, **Quando** o BFF processa a requisição, **Então** o resultado é idempotente e nenhuma assinatura duplicada é criada.
9. **Dado** que o usuário possui uma assinatura ativa e deseja trocar de plano, **Quando** ele acessa o gerenciamento da assinatura, **Então** o aplicativo o direciona para a Google Play e não inicia uma nova compra.

---

### História de Usuário 2 — Cancelamento pelo usuário durante o fluxo de compra ou autenticação (Prioridade: P1)

O usuário inicia o fluxo de contratação mas cancela a autenticação Google antes do pagamento, ou cancela o pagamento na Google Play. O aplicativo retorna à tela de planos sem apresentar mensagem de erro técnico e sem ativar uma assinatura.

**Por que esta prioridade**: Cancelamento é o caminho mais frequente após iniciar o fluxo; tratá-lo incorretamente gera erros visíveis e frustração.

**Teste independente**: Pode ser validado iniciando o fluxo de contratação e cancelando a autenticação Google ou o pagamento; o estado de acesso Premium deve permanecer inalterado.

**Cenários de Aceite**:

1. **Dado** que o usuário iniciou o fluxo de compra, **Quando** ele cancela na tela da Google Play, **Então** o aplicativo retorna à tela de planos sem exibir mensagem de erro técnico e sem criar conta ou assinatura.
2. **Dado** que o usuário selecionou um plano mas cancelou a autenticação Google, **Quando** o aplicativo retorna à tela de planos, **Então** nenhum pagamento é iniciado e o usuário permanece Free.
3. **Dado** que o usuário está na tela de planos, **Quando** ele tenta iniciar novo fluxo de compra enquanto outro já está em andamento, **Então** o aplicativo impede o início simultâneo.

---

### História de Usuário 3 — Restauração de compra após reinstalação ou troca de dispositivo (Prioridade: P2)

O usuário reinstala o aplicativo ou troca de aparelho, autentica-se com a conta Google vinculada à assinatura ativa e recupera automaticamente o acesso Premium. Caso o BFF ainda não tenha registrado a assinatura, o fluxo de restauração permite sua validação e associação sem criar duplicações.

**Por que esta prioridade**: Garante que o usuário não perca o benefício já pago em situações comuns de troca de dispositivo ou reinstalação.

**Teste independente**: Pode ser validado desinstalando o aplicativo, reinstalando e autenticando com uma conta com assinatura ativa; o Premium deve ser reconhecido.

**Cenários de Aceite**:

1. **Dado** que o usuário possui assinatura ativa e reinstalou o aplicativo, **Quando** ele autentica com a conta vinculada à assinatura, **Então** o BFF reconhece a assinatura e retorna o usuário como Premium.
2. **Dado** que existe compra válida ainda não associada no BFF, **Quando** o usuário aciona "Restaurar compras", **Então** o aplicativo envia os dados ao BFF para validação e associação.
3. **Dado** que a restauração é bem-sucedida, **Quando** o BFF confirma a assinatura, **Então** o aplicativo libera o Premium sem criar assinatura duplicada.
4. **Dado** que o usuário não possui compra válida, **Quando** ele aciona "Restaurar compras", **Então** o aplicativo informa que não há assinatura a restaurar.

---

### História de Usuário 4 — Renovação automática e manutenção do acesso Premium (Prioridade: P2)

A Google Play executa a renovação financeira automaticamente a cada período sem exigir nova ação do usuário. O BFF atualiza o status da assinatura quando ocorrem renovação, cancelamento da renovação automática, suspensão, período de graça, reembolso ou revogação. O acesso Premium é mantido enquanto a assinatura estiver válida e removido quando não houver mais direito.

**Por que esta prioridade**: Sem renovação automática funcional, o usuário precisaria recomprar manualmente a cada período — inaceitável para um modelo de assinatura.

**Teste independente**: Pode ser validado simulando eventos de renovação, suspensão e expiração via Google Play Developer API e verificando o reflexo no status do usuário no BFF.

**Cenários de Aceite**:

1. **Dado** que a assinatura está ativa, **Quando** a Google Play renova automaticamente o período, **Então** o BFF atualiza a data de expiração e o usuário continua Premium sem interação.
2. **Dado** que o usuário cancelou a renovação automática mas ainda está dentro do período pago, **Quando** o BFF processa o evento de cancelamento, **Então** o usuário permanece Premium até o término do período já pago.
3. **Dado** que o período pago expirou ou a assinatura foi revogada, **Quando** o BFF processa o evento de expiração ou revogação, **Então** o usuário é rebaixado ao plano Free.
4. **Dado** que a renovação falhou e a assinatura entrou em período de graça, **Quando** o BFF processa o evento, **Então** o usuário permanece Premium durante o período de graça.
5. **Dado** que a assinatura está suspensa por falha de pagamento, **Quando** o BFF processa o evento de suspensão, **Então** o usuário perde o acesso Premium enquanto a suspensão estiver ativa.
6. **Dado** que uma assinatura suspensa é recuperada, **Quando** o BFF processa o evento de recuperação, **Então** o usuário volta a ter acesso Premium.
7. **Dado** que ocorreu reembolso, **Quando** o BFF processa o evento, **Então** o acesso Premium é removido.

---

### História de Usuário 5 — Gerenciamento da assinatura e exibição de status (Prioridade: P3)

O usuário Premium visualiza o status atual da sua assinatura, a próxima data de cobrança ou término de acesso (quando disponíveis), e acessa diretamente o gerenciamento da assinatura na Google Play a partir do perfil do aplicativo.

**Por que esta prioridade**: Melhora a experiência e a transparência, mas o aplicativo é utilizável sem esse detalhamento.

**Teste independente**: Pode ser validado abrindo o perfil de um usuário Premium e verificando a exibição correta do status e o redirecionamento para o gerenciamento na Google Play.

**Cenários de Aceite**:

1. **Dado** que o usuário está autenticado como Premium, **Quando** ele acessa a tela de perfil, **Então** o status da assinatura é exibido com informações disponíveis (estado, data de próxima cobrança ou término quando aplicável).
2. **Dado** que o usuário visualiza o perfil Premium, **Quando** ele aciona a ação de gerenciar assinatura, **Então** é redirecionado para a tela de gerenciamento da Google Play.
3. **Dado** que a assinatura está em estado de cancelamento pendente (período pago ainda vigente), **Quando** o usuário visualiza o perfil, **Então** o aplicativo exibe o status de cancelamento e a data de término do acesso.
4. **Dado** que a assinatura está pendente, **Quando** o usuário visualiza o perfil, **Então** o aplicativo apresenta o estado pendente sem liberar funcionalidades Premium.

---

### Casos de Borda

- O usuário fecha o aplicativo durante o pagamento — a compra pode ter sido aprovada pela Google Play sem que o aplicativo tenha concluído o fluxo; na próxima abertura autenticada o aplicativo deve consultar compras existentes e concluir a validação.
- O pagamento é aprovado e a autenticação Google é concluída, mas o aplicativo perde conexão antes de chamar o BFF — o aplicativo deve tentar reenviar na próxima oportunidade sem criar duplicação.
- O BFF está temporariamente indisponível após a compra — o aplicativo deve apresentar estado de processamento e permitir nova tentativa; a falha temporária não deve apagar assinatura previamente confirmada sem evidência de expiração.
- A Google Play está temporariamente indisponível durante a validação no BFF — o BFF deve tratar a indisponibilidade com retentativas limitadas e retornar erro ao aplicativo.
- A mesma compra é enviada mais de uma vez ao BFF — o processamento deve ser idempotente.
- O usuário já possui assinatura ativa e tenta adquirir outro plano — o aplicativo deve informar sobre a assinatura em vigor.
- A assinatura está cancelada, mas ainda dentro do período pago — o usuário permanece Premium até o término do período.
- A renovação falha e a assinatura entra em período de graça — o usuário mantém o acesso durante o período de graça.
- A assinatura é suspensa por problema de pagamento — o acesso Premium é removido temporariamente.
- A compra é reembolsada ou revogada — o BFF remove o acesso Premium.
- O usuário troca de dispositivo — o acesso é recuperado após autenticação com a conta vinculada.
- O usuário troca a conta Google durante o fluxo de contratação — o aplicativo cancela o fluxo pendente e exige uma nova tentativa vinculada à conta recém-autenticada.
- Existe compra válida ainda não vinculada à conta autenticada no Nutrity — o fluxo de restauração deve permitir a associação mediante validação.

---

## Requisitos *(obrigatório)*

### Requisitos Funcionais

#### Acesso à Tela de Planos e Fluxo de Compra

- **RF-001**: A tela de planos Premium DEVE ser acessível a qualquer usuário, autenticado ou não.
- **RF-002**: O aplicativo NÃO DEVE exigir autenticação prévia para que o usuário visualize os planos, mas DEVE exigi-la antes de iniciar o pagamento.
- **RF-003**: Ao selecionar um plano sem estar autenticado, o aplicativo DEVE conduzir o usuário para autenticar com uma conta Google antes de iniciar o pagamento.
- **RF-004**: A conta Google autenticada antes do pagamento DEVE ser a conta vinculada à assinatura no BFF.

#### Apresentação de Planos

- **RF-005**: O aplicativo DEVE apresentar os planos e ofertas retornados pela Google Play, incluindo preço, periodicidade e condições.
- **RF-006**: O aplicativo DEVE refletir fielmente as informações de plano e preço fornecidas pela Google Play, sem modificações pelo Nutrity.

#### Fluxo de Compra

- **RF-007**: O aplicativo DEVE utilizar exclusivamente o fluxo oficial da Google Play para processar o pagamento.
- **RF-008**: O aplicativo NÃO DEVE solicitar, exibir campos ou armazenar dados de cartão de crédito ou débito.
- **RF-009**: Após a conclusão do pagamento, o aplicativo DEVE enviar os dados da compra e o token da conta Google autenticada ao BFF.
- **RF-010**: O aplicativo DEVE impedir o início de múltiplos fluxos de compra simultâneos.
- **RF-011**: O aplicativo DEVE exibir estado de carregamento e impedir ações duplicadas durante o processamento de uma compra.

#### Validação e Ativação pelo BFF

- **RF-012**: O BFF DEVE validar a compra diretamente junto à Google Play antes de registrar qualquer assinatura.
- **RF-013**: O BFF NÃO DEVE confiar nos dados recebidos do aplicativo como prova suficiente de pagamento; a validação na Google Play é obrigatória.
- **RF-014**: Somente após validação bem-sucedida, o BFF DEVE criar ou identificar a conta do usuário, registrar a assinatura e reconhecê-lo como Premium.
- **RF-015**: O processamento de uma mesma compra pelo BFF DEVE ser idempotente — envios repetidos do mesmo identificador de compra NÃO DEVEM criar assinaturas duplicadas.
- **RF-016**: O BFF DEVE impedir que a mesma compra seja associada a usuários diferentes.
- **RF-016A**: O BFF DEVE rejeitar a associação quando os identificadores protegidos da compra não corresponderem à conta Google autenticada antes do pagamento.
- **RF-017**: Após confirmação pelo BFF, o usuário DEVE ter acesso Premium imediatamente, sem etapa adicional de login.

#### Persistência da Assinatura no BFF

- **RF-018**: O BFF DEVE persistir, para cada assinatura, pelo menos: provedor de pagamento, identificador do produto, identificador do plano, identificador da compra, status, data de início, data de expiração e situação da renovação automática.
- **RF-019**: O BFF DEVE ser a fonte de verdade para determinar se o usuário possui plano Premium ativo.

#### Estados da Assinatura

- **RF-020**: O BFF DEVE reconhecer e tratar os seguintes estados de assinatura: pendente, ativa, em período de teste, em período de graça, suspensa, cancelada com acesso ainda vigente, expirada, reembolsada e revogada.
- **RF-021**: Funcionalidades Premium DEVEM ser liberadas somente quando o BFF reconhece a assinatura como ativa ou em período de teste ou de graça.
- **RF-022**: Compras com status pendente NÃO DEVEM liberar acesso Premium antes da confirmação.

#### Renovação Automática

- **RF-023**: A renovação financeira DEVE ser executada exclusivamente pela Google Play; o usuário NÃO DEVE precisar realizar nova compra a cada período.
- **RF-024**: O BFF DEVE atualizar o status da assinatura quando receber notificações de renovação, cancelamento, expiração, suspensão, recuperação, período de graça e reembolso.
- **RF-024A**: O BFF DEVE reconciliar todas as assinaturas ativas com a Google Play ao menos uma vez por hora, para corrigir atraso, perda ou falha no processamento de notificações.
- **RF-024B**: Antes de aplicar uma mudança de status recebida por notificação, o BFF DEVE validar o estado atual da assinatura na Google Play para evitar que eventos atrasados ou fora de ordem revertam um estado mais recente.
- **RF-025**: O cancelamento da renovação automática NÃO DEVE remover imediatamente o Premium quando ainda existir período pago vigente; o acesso deve ser mantido até o término desse período.
- **RF-026**: Quando o direito de acesso não for mais válido, o BFF DEVE rebaixar o usuário para o plano Free.

#### Restauração de Compras

- **RF-027**: O aplicativo DEVE disponibilizar a opção de restaurar compras para usuários autenticados que reinstalaram o aplicativo, trocaram de aparelho ou tiveram a validação interrompida após o pagamento.
- **RF-028**: O fluxo de restauração DEVE exigir autenticação Google antes de enviar dados de compra ao BFF para validação e associação.
- **RF-029**: A restauração NÃO DEVE criar assinaturas duplicadas.
- **RF-030**: Ao autenticar, o BFF DEVE reconhecer automaticamente uma assinatura ainda ativa vinculada à conta do usuário.

#### Inicialização do Aplicativo

- **RF-031**: O aplicativo DEVE consultar o BFF durante sua inicialização para obter o plano efetivo do usuário autenticado.
- **RF-032**: O aplicativo pode manter o plano em cache local para apresentação, mas DEVE reconciliá-lo periodicamente com o BFF.
- **RF-033**: Falhas temporárias de comunicação com o BFF NÃO DEVEM apagar imediatamente uma assinatura anteriormente confirmada sem que exista evidência de expiração ou revogação.

#### Gerenciamento da Assinatura

- **RF-034**: O aplicativo DEVE disponibilizar acesso direto ao gerenciamento da assinatura na Google Play a partir da tela de perfil.
- **RF-035**: A tela de perfil Premium DEVE exibir o status atual da assinatura e, quando disponível, a próxima data de cobrança ou término do acesso.
- **RF-035A**: Para usuário com assinatura ativa, o aplicativo DEVE exibir o plano vigente e encaminhar qualquer troca de plano para o gerenciamento da assinatura na Google Play.

#### Experiência do Usuário

- **RF-036**: Em caso de cancelamento pelo usuário durante o pagamento, o aplicativo DEVE retornar à tela de planos sem exibir mensagem de erro técnico.
- **RF-037**: Se o usuário cancela a autenticação Google antes do pagamento, o aplicativo DEVE informar que a autenticação é necessária para assinar e permitir nova tentativa.
- **RF-038**: Em caso de falha técnica, o aplicativo DEVE apresentar mensagem clara e permitir nova tentativa quando apropriado.
- **RF-039**: Compras pendentes DEVEM ser apresentadas ao usuário como pendentes, sem liberar funcionalidades Premium.
- **RF-040**: Em caso de sucesso na ativação, o aplicativo DEVE informar ao usuário que o Premium foi ativado.

#### Segurança e Auditoria

- **RF-041**: Toda associação de compra ao BFF DEVE exigir um token de autenticação válido do usuário.
- **RF-042**: Nenhum segredo utilizado para consultar a Google Play DEVE ser incluído no aplicativo cliente.
- **RF-043**: Tokens e identificadores de compra NÃO DEVEM aparecer integralmente em logs.
- **RF-044**: O BFF DEVE registrar auditoria das validações e das mudanças relevantes de status de assinatura.

---

### Entidades Principais

- **Assinatura**: Representa o vínculo entre um usuário e um plano Premium contratado. Contém identificação da compra, provedor, produto, plano, status atual, datas de início e expiração, situação da renovação automática e histórico de eventos de status.

- **Plano**: Representa uma opção de assinatura disponível para contratação. Contém identificação do produto na Google Play, periodicidade, preço e condições apresentadas ao usuário.

- **Evento de Status**: Representa uma mudança no ciclo de vida da assinatura (renovação, cancelamento, suspensão, reembolso etc.) recebida da Google Play, usada pelo BFF para manter o status atual e o histórico auditável.

- **Usuário**: Entidade já existente no sistema, autenticada via conta Google. Associada a uma assinatura ativa quando Premium.

---

## Critérios de Sucesso *(obrigatório)*

### Resultados Mensuráveis

- **CS-001**: Um usuário sem conta consegue concluir o fluxo completo — seleção do plano, autenticação Google e pagamento — obtendo acesso Premium em uma única sessão, sem precisar reiniciar o aplicativo.
- **CS-002**: Nenhum dado de cartão é coletado ou armazenado pelo Nutrity em nenhum ponto do fluxo.
- **CS-003**: Uma compra cancelada pelo usuário não resulta em ativação do Premium em 100% dos casos.
- **CS-004**: Uma compra pendente não libera acesso Premium antes da confirmação em 100% dos casos.
- **CS-005**: Uma compra válida confirmada pelo BFF ativa o Premium imediatamente, sem etapa adicional de login após o pagamento.
- **CS-006**: O envio repetido de um mesmo identificador de compra não cria assinaturas duplicadas em 100% dos casos.
- **CS-007**: Após reinstalação e autenticação com conta vinculada a assinatura ativa, o usuário recupera o acesso Premium em até uma sessão.
- **CS-008**: O cancelamento da renovação automática mantém o acesso Premium até o fim do período já pago em 100% dos casos.
- **CS-009**: Expiração ou revogação confirmada pelo BFF remove o acesso Premium sem necessidade de ação manual.
- **CS-010**: Renovações automáticas mantêm o acesso Premium sem qualquer interação do usuário.
- **CS-010A**: A reconciliação periódica corrige, em até uma hora, divergências entre o status local e o status confirmado pela Google Play, inclusive quando uma notificação não tiver sido recebida.
- **CS-010B**: Eventos atrasados ou fora de ordem não revertem o status de uma assinatura para um estado diferente daquele confirmado pela Google Play.
- **CS-011**: O BFF rejeita 100% das tentativas de associar uma compra a um usuário diferente daquele que a realizou.
- **CS-012**: O gerenciamento da assinatura na Google Play é acessível a partir do perfil em no máximo dois toques.

---

## Premissas

- Usuários do plano Free não possuem conta no Nutrity; a conta é criada ou identificada quando o usuário autentica com Google antes do pagamento.
- Todo usuário Premium possui uma conta Google vinculada antes do pagamento.
- A autenticação Google já está implementada no aplicativo e no BFF (OAuth funcional).
- O BFF já emite e valida tokens de autenticação; o token é utilizado para associar a compra à conta do usuário.
- O aplicativo é distribuído exclusivamente para Android na plataforma Google Play para esta feature.
- O BFF possui capacidade de se comunicar com a Google Play Developer API para validação de compras.
- Os produtos e planos de assinatura já estão configurados no Google Play Console antes da liberação da feature.
- Notificações em tempo real de eventos do ciclo de vida da assinatura (renovação, cancelamento, reembolso etc.) chegam ao BFF via mecanismo de notificação da Google Play.
- O BFF executa reconciliação das assinaturas ativas ao menos uma vez por hora para complementar as notificações em tempo real.
- O BFF já possui infraestrutura de logs estruturados com identificador de correlação, conforme a constituição.
- A integração com Apple App Store está fora do escopo desta feature.
- Cupons, PIX, boleto ou gateway próprio estão fora do escopo desta feature.
- Trocas de plano dentro do aplicativo estão fora do escopo; elas são gerenciadas exclusivamente na Google Play.
- A alteração das funcionalidades Premium já existentes (IA, macronutrientes, armazenamento em nuvem, ausência de anúncios) está fora do escopo.
- Migração do H2 para PostgreSQL e sincronização de refeições estão fora do escopo.
