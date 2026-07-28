# Especificação da Funcionalidade: Sincronização de Dados Online e Offline

**Feature Branch**: `004-sincronizar-dados-offline`

**Criado em**: 2026-07-27

**Status**: Aprovada para implementação

**Entrada**: Descrição do usuário: "Sincronizar os dados de uso não autenticado e autenticado, online e offline. Sem login, as informações permanecem apenas no app. Ao entrar com uma conta Google premium, enviar ao BFF os dados locais ainda não cadastrados para o usuário e carregar no banco local os dados existentes no BFF. Ao sair da conta, limpar o banco de dados local do app."

## Clarifications

### Session 2026-07-27

- Q: Quando dois dispositivos alterarem offline o mesmo registro e depois sincronizarem, qual versão deve prevalecer? → A: A alteração com data mais recente prevalece.
- Q: Quais dados devem participar da sincronização nesta primeira versão? → A: Refeições e metas nutricionais.
- Q: O que deve acontecer quando o premium expirar enquanto a pessoa continua autenticada? → A: Pausar a sincronização, manter os dados locais e guardar novas alterações até a renovação; o uso de IA segue as condições de uma pessoa sem assinatura ativa.
- Q: Após o login premium, a pessoa pode usar o app enquanto a primeira sincronização ainda está em andamento? → A: Sim; usa os dados locais imediatamente e a integração ocorre em segundo plano.
- Q: Qual momento define a alteração mais recente entre dispositivos? → A: O momento em que a alteração foi feita no dispositivo.

## Cenários de Usuário e Testes *(obrigatório)*

### História de Usuário 1 - Integrar dados locais ao entrar (Prioridade: P1)

Como pessoa que usou o app sem login, quero entrar com minha conta Google premium e unir meus dados locais aos dados já associados à minha conta, para continuar meu histórico sem duplicações nem perdas.

**Por que esta prioridade**: Esta é a principal transição da funcionalidade e protege o histórico criado antes da autenticação.

**Teste independente**: Pode ser testado criando registros no modo não autenticado, preparando outros registros na conta premium, realizando o login e confirmando que ambos os conjuntos aparecem uma única vez no app e na conta.

**Cenários de aceitação**:

1. **Dado** que há dados somente no app e a conta premium não possui esses registros, **Quando** a pessoa entra com Google enquanto está online, **Então** os registros locais são associados à conta, salvos remotamente e continuam disponíveis no app.
2. **Dado** que a conta premium possui dados que não existem no app, **Quando** a pessoa entra enquanto está online, **Então** esses dados são carregados para o armazenamento local e ficam disponíveis no app.
3. **Dado** que o mesmo registro já existe local e remotamente, **Quando** a sincronização de login ocorre, **Então** o registro aparece apenas uma vez e a versão remota prevalece em caso de divergência.
4. **Dado** que a sincronização é interrompida e depois repetida, **Quando** ela é retomada, **Então** registros já processados não são duplicados e os restantes são sincronizados.
5. **Dado** que o login premium foi concluído e a sincronização inicial continua em andamento, **Quando** a pessoa usa o app, **Então** os dados locais ficam disponíveis imediatamente e novas alterações são registradas como pendentes sem interromper a integração.
6. **Dado** que a pessoa está na seleção de planos, **Quando** escolhe recuperar compra e autentica uma conta Google com premium ativo, **Então** o app restaura a sessão, abre a área autenticada e inicia a recuperação dos dados da conta.
7. **Dado** que a pessoa tenta recuperar compra com uma conta sem premium ativo, **Quando** a validação termina, **Então** nenhuma sessão premium é criada, uma mensagem identifica o e-mail consultado e informa que ele não possui conta Premium ativa, e a seleção de planos volta a ser exibida.
8. **Dado** que o carregamento inicial termina sem plano previamente selecionado, **Quando** a seleção de planos é exibida, **Então** a ação de recuperar compra fica disponível diretamente nessa tela, sem exigir que a pessoa abra primeiro os detalhes do Premium.
9. **Dado** que a seleção de planos é exibida em uma tela compacta, **Quando** a pessoa compara as opções, **Então** título, benefícios, destaque Premium e ações permanecem legíveis, organizados e acessíveis sem overflow.
10. **Dado** que a pessoa está no paywall, **Quando** compara os planos mensal e anual, **Então** seleção, preço, período, economia e benefícios são apresentados com hierarquia visual clara e sem overflow.
11. **Dado** que a recuperação iniciada diretamente no paywall não encontra uma conta Premium ativa, **Quando** a validação termina, **Então** a mensagem com o e-mail consultado é exibida no próprio paywall.
12. **Dado** que uma pessoa Premium está na Home, **Quando** toca em seu nome, **Então** a tela de perfil e metas é aberta.
13. **Dado** que a pessoa abre o paywall mensal e anual, **Quando** a tela é exibida, **Então** o título “Planos Premium” aparece somente no conteúdo principal, sem repetição na barra superior.
14. **Dado** que a Home é exibida, **Quando** o cabeçalho superior é renderizado, **Então** existe apenas uma pequena margem entre a área segura e o cabeçalho, tanto no modo Free quanto Premium.

---

### História de Usuário 2 - Continuar usando offline (Prioridade: P2)

Como pessoa não autenticada ou como assinante premium autenticado, quero registrar e consultar informações sem internet, para que a indisponibilidade da rede não interrompa o uso principal do app.

**Por que esta prioridade**: O uso offline é um princípio central do produto e impede perda de valor quando a rede ou o serviço remoto está indisponível.

**Teste independente**: Pode ser testado desativando a rede, criando, consultando, alterando e removendo registros e verificando que todas as operações locais continuam disponíveis.

**Cenários de aceitação**:

1. **Dado** que a pessoa não está autenticada e está offline, **Quando** cria, consulta, altera ou remove dados, **Então** as mudanças são mantidas somente no dispositivo e permanecem acessíveis após reiniciar o app.
2. **Dado** que uma pessoa premium autenticada fica offline, **Quando** altera seus dados, **Então** a alteração é salva localmente, identificada como pendente e enviada automaticamente quando a conectividade retornar.
3. **Dado** que o serviço remoto está indisponível, **Quando** a sincronização falha, **Então** o app preserva os dados locais, informa o estado sem bloquear o uso e permite nova tentativa.
4. **Dado** que o premium expira durante uma sessão autenticada, **Quando** a pessoa continua usando o app, **Então** a sincronização permanece pausada, as alterações ficam pendentes no dispositivo até a renovação e as chamadas de IA seguem as regras de uma pessoa sem assinatura ativa.

---

### História de Usuário 3 - Proteger dados ao sair (Prioridade: P3)

Como pessoa autenticada, quero que os dados da minha conta sejam removidos do dispositivo ao sair, para que outra pessoa não tenha acesso ao meu histórico.

**Por que esta prioridade**: A limpeza no logout reduz exposição de dados pessoais em dispositivos compartilhados.

**Teste independente**: Pode ser testado realizando login, carregando dados da conta, efetuando logout e confirmando que nenhum dado ou pendência da conta permanece acessível localmente.

**Cenários de aceitação**:

1. **Dado** que a pessoa premium está autenticada e seus dados estão sincronizados, **Quando** confirma o logout, **Então** os dados locais, pendências de sincronização e informações locais da sessão são removidos.
2. **Dado** que há alterações pendentes e existe conexão, **Quando** a pessoa solicita logout, **Então** o app tenta sincronizá-las antes da limpeza e informa caso alguma alteração não possa ser enviada.
3. **Dado** que há alterações pendentes e não existe conexão, **Quando** a pessoa confirma que deseja sair mesmo assim, **Então** o app avisa que as alterações não sincronizadas serão perdidas, conclui o logout e limpa os dados locais.
4. **Dado** que o logout foi concluído, **Quando** o app é reiniciado sem nova autenticação, **Então** ele inicia com uma base local vazia e permite um novo uso local independente.

### Casos Limite

- O login premium é concluído, mas a rede cai durante a união dos dados; o progresso já confirmado deve ser preservado e a operação deve poder continuar sem duplicar registros.
- Durante a integração inicial, o mesmo registro possui versões local e remota diferentes; a versão remota deve prevalecer e a decisão deve ser informada de forma não intrusiva.
- Dois registros têm conteúdo semelhante, mas identidades diferentes; ambos devem ser preservados, pois sem identidade comum não são considerados duplicados.
- A conectividade oscila ou o serviço remoto excede o tempo de espera; o app deve limitar novas tentativas, manter as pendências e continuar funcional offline.
- O token de acesso expira durante a sincronização; nenhum dado deve ser apagado e a pessoa deve ser orientada a autenticar-se novamente.
- O dispositivo fica sem espaço durante a importação; os dados remotos não devem ser considerados integralmente disponíveis localmente e a pessoa deve receber orientação acionável.
- A conta autenticada não possui premium ativo; a sincronização remota não deve começar e os dados locais existentes devem permanecer intactos.
- A recuperação de compra usa um e-mail inexistente ou sem premium ativo; o BFF não deve criar uma conta nem conceder premium.
- O premium expira durante uma sessão autenticada; a sincronização deve ser pausada, sem apagar dados ou pendências, e retomada após a renovação.
- O app é fechado durante o logout; na próxima abertura, a limpeza iniciada deve ser concluída antes de exibir dados ou permitir outra sessão.

## Requisitos *(obrigatório)*

### Requisitos Funcionais

- **RF-001**: O sistema DEVE permitir criar, consultar, alterar e remover dados no modo não autenticado sem depender de conexão.
- **RF-002**: No modo não autenticado, o sistema DEVE manter os dados exclusivamente no dispositivo e não os associar a uma conta.
- **RF-003**: O sistema DEVE iniciar a integração entre dados locais e remotos somente após autenticação bem-sucedida com uma conta Google premium ativa.
- **RF-004**: No primeiro login premium e em logins posteriores com dados locais, o sistema DEVE enviar para a conta todos os registros locais que ainda não estejam cadastrados remotamente.
- **RF-005**: Após o login premium, o sistema DEVE carregar para o dispositivo todos os registros remotos da conta que ainda não estejam disponíveis localmente.
- **RF-006**: O sistema DEVE atribuir uma identidade estável a cada registro e usar essa identidade para reconhecer o mesmo registro entre dispositivo e conta.
- **RF-007**: A repetição de qualquer etapa de sincronização DEVE produzir o mesmo resultado, sem duplicar registros.
- **RF-008**: Quando versões local e remota do mesmo registro divergirem no início da integração, o sistema DEVE manter a versão remota como versão válida.
- **RF-009**: Registros de identidades diferentes DEVEM ser preservados, mesmo quando tiverem conteúdo semelhante.
- **RF-010**: Depois do login premium, alterações feitas offline DEVEM ser aplicadas imediatamente no dispositivo e marcadas como pendentes de sincronização.
- **RF-011**: O sistema DEVE tentar sincronizar automaticamente as pendências quando detectar conectividade adequada e também permitir nova tentativa iniciada pela pessoa.
- **RF-012**: Falhas de rede, autenticação ou serviço remoto NÃO DEVEM impedir operações locais nem descartar dados ou pendências.
- **RF-013**: O sistema DEVE apresentar estados compreensíveis de sincronização em andamento, concluída, pendente e com falha, incluindo orientação para recuperação quando necessária.
- **RF-014**: Antes de um logout com pendências, o sistema DEVE tentar sincronizá-las quando houver conexão.
- **RF-015**: Se ainda houver pendências no logout, o sistema DEVE informar que elas serão perdidas e exigir confirmação explícita para continuar.
- **RF-016**: Ao concluir o logout, o sistema DEVE remover todos os dados da conta armazenados localmente, todas as pendências, os metadados de sincronização e as informações locais da sessão.
- **RF-017**: Uma limpeza iniciada por logout DEVE ser concluída antes que dados sejam exibidos em uma abertura posterior do app.
- **RF-018**: Após o logout, um novo uso sem autenticação DEVE começar com um conjunto local vazio e independente da conta anterior.
- **RF-019**: Dados de uma conta NÃO DEVEM ser exibidos, enviados ou unidos com os de outra conta.
- **RF-020**: O sistema DEVE preservar os dados locais existentes quando o login falhar, a conta não for premium ou a sincronização inicial não puder ser concluída.
- **RF-021**: O sistema DEVE sincronizar inclusões, alterações e remoções realizadas por uma pessoa premium autenticada, inclusive quando originadas offline.
- **RF-022**: O sistema DEVE registrar somente informações operacionais mínimas para diagnosticar a sincronização, sem incluir conteúdo nutricional, tokens ou outros dados pessoais.
- **RF-023**: Após a integração inicial, quando o mesmo registro tiver alterações conflitantes originadas em dispositivos diferentes, o sistema DEVE manter a alteração realizada mais recentemente, conforme o momento registrado no dispositivo em que a alteração ocorreu.
- **RF-024**: Nesta primeira versão, o sistema DEVE sincronizar somente refeições, seus dados nutricionais associados e a meta nutricional de calorias diárias.
- **RF-025**: Quando o premium expirar durante uma sessão autenticada, o sistema DEVE pausar a sincronização, preservar os dados e pendências locais e manter novas alterações pendentes até a renovação.
- **RF-026**: Enquanto o premium estiver inativo, solicitações de IA DEVEM seguir as mesmas condições, limites e elegibilidade aplicáveis a uma pessoa sem assinatura ativa.
- **RF-027**: Após a renovação do premium, o sistema DEVE retomar a sincronização das pendências preservadas sem duplicar registros.
- **RF-028**: O sistema NÃO DEVE bloquear o uso do app enquanto a sincronização inicial estiver em andamento; os dados locais DEVEM permanecer disponíveis e as novas alterações DEVEM entrar na fila de sincronização.
- **RF-029**: A seleção de planos exibida após o carregamento e os detalhes do Premium DEVEM oferecer recuperação de compra por Google; somente uma conta já existente com premium ativo DEVE restaurar a sessão e iniciar o bootstrap, enquanto uma conta inexistente ou sem premium ativo DEVE permanecer desautenticada e retornar à seleção de planos com aviso que identifique o e-mail consultado.
- **RF-030**: A seleção de planos DEVE apresentar hierarquia visual clara entre introdução, opções Free e Premium, recuperação de compra e continuidade gratuita, usando componentes Material 3, tokens visuais e layout adaptável sem alterar os fluxos de navegação.
- **RF-031**: O paywall DEVE diferenciar visualmente planos mensal e anual, indicar inequivocamente a opção selecionada, apresentar os benefícios uma única vez e permanecer utilizável em largura compacta.
- **RF-032**: Quando uma recuperação sem conta Premium ativa não tiver a seleção de planos como tela de origem, o paywall DEVE permanecer aberto e exibir a mensagem localizada com o e-mail consultado.
- **RF-033**: Na Home de uma pessoa Premium, tanto o nome exibido quanto a foto DEVEM abrir a tela de perfil e metas.
- **RF-034**: O paywall mensal e anual DEVE exibir o título da tela uma única vez no conteúdo principal; a barra superior DEVE manter apenas a ação de voltar.
- **RF-035**: A Home DEVE usar a menor margem vertical do design system entre a área segura e seu cabeçalho superior, igualmente para pessoas Free e Premium.

### Entidades Principais

- **Conta do usuário**: Identidade autenticada por Google, com indicação de elegibilidade premium e separação obrigatória dos dados de outras contas.
- **Registro sincronizável**: Informação de domínio mantida pelo app, como uma refeição, com identidade estável, conteúdo, momento da última alteração registrado no dispositivo de origem e estado de remoção.
- **Cópia local**: Representação disponível no dispositivo e usada como fonte imediata para todas as operações, inclusive offline.
- **Cópia remota**: Representação associada à conta premium, usada para continuidade entre sessões e dispositivos.
- **Pendência de sincronização**: Alteração local ainda não confirmada remotamente, identificando a operação, o registro e seu estado de tentativa.
- **Estado de sincronização**: Situação observável do processo, incluindo pendente, em andamento, concluído, interrompido e com falha recuperável.
- **Meta nutricional**: Objetivo diário de calorias definido pela pessoa, com identidade estável, período de validade, valor-alvo e informações de modificação necessárias à sincronização.

## Critérios de Sucesso *(obrigatório)*

### Resultados Mensuráveis

- **CS-001**: Em testes com até 1.000 registros locais e 1.000 remotos, 100% dos registros de identidades distintas ficam disponíveis no app e na conta após uma sincronização concluída, sem duplicações por identidade.
- **CS-002**: 100% das operações de criar, consultar, alterar e remover dados continuam disponíveis durante indisponibilidade de rede.
- **CS-003**: Após o retorno da conectividade, pelo menos 95% das sincronizações com até 100 pendências são concluídas em até 30 segundos em condições normais.
- **CS-004**: Repetir a sincronização três vezes sobre o mesmo conjunto não altera a quantidade nem o conteúdo final dos registros.
- **CS-005**: Em 100% dos logouts concluídos, nenhum dado, pendência ou informação de sessão da conta anterior pode ser acessado após reiniciar o app.
- **CS-006**: Em testes de interrupção em cada etapa da integração, 100% dos registros locais não confirmados permanecem recuperáveis enquanto o logout não for confirmado.
- **CS-007**: Pelo menos 90% das pessoas em teste conseguem identificar se seus dados estão sincronizados, pendentes ou com erro sem assistência.

## Premissas

- O escopo sincronizável desta versão limita-se a refeições, seus dados nutricionais associados e à meta de calorias diárias; perfil, preferências e configurações exclusivas do dispositivo permanecem locais.
- A autenticação Google e a validação do status premium já existem ou serão disponibilizadas como dependências desta funcionalidade.
- A identidade estável de um registro é a única base segura para deduplicação; sem identidade compartilhada, registros semelhantes são tratados como distintos.
- Na integração inicial, a cópia remota prevalece quando o mesmo registro diverge, evitando que dados já consolidados na conta sejam sobrescritos silenciosamente.
- Após a integração inicial, cada alteração possui uma data e hora de modificação, com fuso definido, registrada no dispositivo de origem e comparável entre dispositivos para determinar a versão mais recente em caso de conflito.
- Uma pessoa pode continuar usando o app localmente sem login ou sem premium, mas sincronização entre dispositivo e conta é benefício exclusivo de conta premium ativa.
- Confirmar logout autoriza a exclusão irreversível das alterações que permanecerem somente no dispositivo, após aviso explícito.

## Fora de Escopo

- Sincronização remota para contas sem premium.
- União automática entre duas contas de usuário diferentes.
- Recuperação, após o logout, de dados que nunca foram confirmados remotamente.
- Deduplicação baseada apenas em descrição, data, calorias ou semelhança de conteúdo.
- Colaboração ou compartilhamento de dados entre usuários.
