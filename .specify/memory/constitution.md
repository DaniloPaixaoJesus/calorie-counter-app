# Constitution do Contador de Calorias Mobile

## Core Principles

### I. Idioma
Todos os arquivos em `specs/**` DEVEM ser escritos integralmente em portugues do Brasil,
incluindo especificação, plano, tarefas, pesquisa, modelo de dados, quickstart, contratos e
ADRs. Identificadores de codigo e termos consolidados da stack DEVEM permanecer em ingles.

Racional: artefatos acessiveis reduzem ambiguidades sem contrariar convencoes tecnicas.

### II. Simplicidade acima de complexidade
Cada funcionalidade DEVE adotar a solucao mais simples capaz de atender ao requisito atual.
Abstracoes prematuras, dependencias desnecessarias e infraestrutura sem uso comprovado sao
proibidas no MVP. Toda nova dependencia ou novo servico DEVE ter justificativa, alternativa
mais simples avaliada e impacto operacional registrados no `plan.md`.

Racional: simplicidade acelera entregas, melhora manutencao e reduz risco de regressao.

### III. Offline First
Registro, consulta, edicao e remocao de refeicoes DEVEM continuar disponiveis sem internet.
Operacoes remotas DEVEM expor estados de carregamento, timeout e erro e oferecer recuperacao
sem perda dos dados locais. IA, autenticacao e sincronizacao PODEM exigir rede quando isso
estiver explicito na especificacao e no plano. Indisponibilidade do BFF NAO DEVE impedir o
uso das funcionalidades locais.

Racional: o valor central do produto depende de uso rapido e confiavel em qualquer contexto.

### IV. Arquitetura e dependencias
Codigo novo DEVE respeitar as fronteiras `presentation`, `application`, `domain` e
`infrastructure`, ainda que agrupadas por feature. O dominio NAO DEVE importar Flutter,
persistencia, HTTP, Spring ou SDKs de providers externos. Comunicacao com armazenamento,
rede, autenticacao e IA DEVE ocorrer por contratos substituiveis.

Dependencias DEVEM apontar para o dominio; adapters implementam contratos definidos nas
camadas internas. Excecoes a essas fronteiras DEVEM constar na tabela de complexidade do
plano e possuir estrategia de remocao.

Racional: fronteiras explicitas permitem testes isolados e troca de tecnologia.

### V. Material 3, acessibilidade e experiencia
Material 3 (`useMaterial3: true`) e o sistema visual padrao do app. Cores, tipografia,
espacamento, raios, elevacao e breakpoints DEVEM vir do tema ou de tokens centralizados;
valores visuais repetidos diretamente em widgets NAO DEVEM ser introduzidos. Componentes
Cupertino somente PODEM ser usados quando uma convencao nativa da plataforma justificar a
excecao.

Fluxos DEVEM minimizar interacoes e tratar estados vazio, carregando, sucesso, indisponivel
e erro. Controles DEVEM possuir rotulos semanticos, area de toque adequada, contraste
legivel, suporte a escala de texto e layout sem overflow nos tamanhos definidos no plano.
Informacao NAO DEVE depender apenas de cor.

Racional: consistencia visual e acessibilidade sao requisitos funcionais da experiencia.

### VI. Dados, persistencia e sincronizacao
SQLite e a fonte local de verdade para refeicoes no app. Acesso a dados DEVE ocorrer por
repositorios; widgets e ViewModels NAO DEVEM executar SQL. Alteracoes de schema DEVEM usar
migracoes versionadas, preservar dados existentes e possuir teste de migracao.

Modelos locais e DTOs remotos DEVEM permanecer separados. Datas persistidas ou transmitidas
DEVEM ter fuso e formato definidos no contrato. Sincronizacao remota, quando adicionada,
DEVE definir identidade, idempotencia, resolucao de conflitos e comportamento offline antes
da implementacao.

Racional: dados do usuario precisam sobreviver a evolucoes do produto com semantica clara.

### VII. Testes por risco
Toda regra de dominio e aplicacao alterada DEVE possuir teste unitario. Repositorios,
migracoes, adapters externos e contratos HTTP alterados DEVEM possuir teste de integracao
ou contrato. Fluxos e estados visuais criticos DEVEM possuir widget test. Correcoes de bug
DEVEM incluir teste que falhe sem a correcao quando tecnicamente viavel.

Testes DEVEM ser deterministas: relogio, rede, armazenamento e providers externos DEVEM ser
controlaveis por doubles ou fixtures. Chamadas reais a servicos pagos NAO DEVEM ocorrer na
suite automatizada padrao.

Racional: a profundidade do teste acompanha o risco e protege as fronteiras arquiteturais.

### VIII. IA isolada e degradavel
Providers de IA DEVEM ser acessados por adapters; regras de negocio NAO DEVEM depender de
um provider especifico. Prompts, parsing e validacao da resposta DEVEM ficar no BFF, e
segredos de provider NUNCA DEVEM ser embarcados no app. Saidas de IA DEVEM ser tratadas como
nao confiaveis, validadas contra o contrato e apresentadas ao usuario para revisao quando
afetarem dados persistidos.

Timeouts, limites de uso, fallback e mensagens de indisponibilidade DEVEM ser definidos.
Logs NAO DEVEM conter prompts, tokens, descricoes de refeicoes ou respostas completas sem
uma decisao explicita de privacidade.

Racional: IA e uma dependencia probabilistica, remota e sensivel a custo e privacidade.

### IX. MVP Primeiro
O projeto DEVE evoluir em fatias verticais pequenas. Cada feature DEVE entregar valor
isolado, ter criterios de aceite mensuraveis e permitir validacao independente. O sucesso
inicial DEVE ser medido por velocidade de uso, estabilidade e clareza, nao pela quantidade
de funcionalidades.

Racional: entregas pequenas maximizam aprendizado e reduzem risco.

### X. Arquitetura Flutter e Dart
Flutter e Dart DEVEM seguir null safety, `flutter_lints`, `dart format` e APIs publicas com
tipos explicitos. Widgets DEVEM ser pequenos, composiveis e preferencialmente imutaveis, com
construtores `const` quando aplicavel. Regras de negocio e acesso a infraestrutura NAO DEVEM
residir em widgets.

Provider com `ChangeNotifier` e a abordagem padrao de estado do MVP. Estado efemero de UI
DEVE permanecer local; estado de feature fica em ViewModels; regras e invariantes ficam no
dominio. Outra biblioteca de estado somente PODE ser adotada mediante ADR que demonstre
necessidade, custo de migracao e beneficio verificavel.

Racional: um padrao unico reduz acoplamento e evita complexidade concorrente.

### XI. Arquitetura do BFF e contratos de API
O BFF DEVE permanecer em Java 21 e Spring Boot, separado em API, dominio/aplicacao e
infraestrutura. Controllers DEVEM limitar-se a transporte, autenticacao e delegacao;
regras de negocio ficam em servicos e integracoes externas em adapters. DTOs de entrada
DEVEM usar validacao declarativa e erros DEVEM seguir um formato consistente, sem expor
stack traces ou detalhes internos.

Contratos HTTP DEVEM ser documentados em `specs/**/contracts/` ou OpenAPI. Mudancas
incompativeis DEVEM criar nova versao de endpoint ou incluir plano de migracao coordenado
com o app. Operacoes de escrita remota DEVEM declarar idempotencia e limites de timeout.

Racional: o BFF protege o cliente de providers externos e exige contratos previsiveis.

### XII. Seguranca, privacidade e observabilidade
Segredos e credenciais DEVEM vir de variaveis de ambiente ou gerenciador de segredos e
NUNCA ser versionados. Endpoints nao publicos DEVEM aplicar autenticacao/autorizacao,
validacao de entrada e rate limiting proporcional ao risco. Dados pessoais e tokens NAO
DEVEM aparecer em logs; coleta e retencao DEVEM ser minimizadas.

O BFF DEVE produzir logs estruturados com identificador de correlacao, operacao, resultado e
latencia, sem payload sensivel. Health checks e metricas DEVEM permitir distinguir falha do
BFF, autenticacao, persistencia e provider externo. O app DEVE registrar erros tecnicos sem
conteudo pessoal e apresentar mensagens acionaveis ao usuario.

Racional: operacao segura requer diagnostico suficiente sem comprometer privacidade.

### XIII. Portoes de qualidade
Antes de concluir uma mudanca Flutter, DEVEM passar `dart format`, `flutter analyze`,
`flutter test` e a validacao manual dos criterios de aceite afetados. Antes de concluir uma
mudanca no BFF, DEVEM passar `./mvnw test` e os testes de contrato ou integracao afetados.
Mudancas em ambos os lados DEVEM validar compatibilidade ponta a ponta do contrato.

Falhas somente PODEM ser aceitas com justificativa, risco, responsavel e prazo registrados
no PR. Documentacao e quickstart afetados DEVEM ser atualizados na mesma entrega.

Racional: portoes objetivos impedem que defeitos conhecidos sejam tratados como conclusao.

## Decisoes Arquiteturais

- O repositorio e um monorepo: cliente em `app/`, BFF em `bff/` e artefatos em `specs/`.
- O cliente usa Flutter/Dart, Material 3, Provider/ChangeNotifier e SQLite.
- O BFF usa Java 21, Spring Boot e adapters para providers externos.
- O app preserva operacoes locais offline e usa o BFF para IA, autenticacao e dados remotos.
- Contratos entre app e BFF DEVEM ser explicitos, versionaveis e testados nos dois lados.
- Novas decisoes transversais ou trocas de stack DEVEM ser registradas em ADR no diretorio
  da feature e referenciadas pelo `plan.md`.

## Diretrizes Tecnicas e de Produto

- A experiencia principal e registrar refeicoes rapidamente e acompanhar dados nutricionais.
- Nova tecnologia DEVE resolver um requisito atual e respeitar os limites de privacidade.
- Estimativas de IA DEVEM ser identificadas como estimativas e permanecer editaveis.
- Performance, acessibilidade e comportamento offline DEVEM ter criterios mensuraveis na spec
  quando forem afetados pela feature.

## Processo Obrigatorio de Desenvolvimento

Toda nova funcionalidade DEVE seguir esta ordem:

1. Specification
2. Clarification, quando necessario
3. Plan e Constitution Check
4. Tasks
5. Implementacao
6. Testes e portoes de qualidade
7. Revisao

Nenhuma implementacao PODE comecar sem especificacao aprovada. O Constitution Check DEVE
ser repetido depois do design. Desvios DEVEM ser registrados antes da implementacao.

## Governance

Esta constituicao prevalece sobre praticas conflitantes em especificacoes, planos, tarefas e
codigo. Todo PR DEVE verificar os principios afetados, os testes exigidos e eventuais
violacoes justificadas.

Emendas DEVEM registrar motivacao, impacto, migracao e artefatos sincronizados. A aprovacao
ocorre pela revisao da mudanca no repositorio. O versionamento segue SemVer:

- MAJOR: remocao ou redefinicao incompativel de principios ou governanca.
- MINOR: novo principio, nova secao obrigatoria ou expansao material de regras.
- PATCH: clarificacao editorial sem mudanca de obrigatoriedade.

Compliance review DEVE ocorrer no `plan.md`, apos o design e em todo PR. Revisores DEVEM
bloquear mudancas que violem uma regra sem justificativa e plano de adequacao.

**Version**: 2.2.0 | **Ratified**: 2026-06-15 | **Last Amended**: 2026-07-27
