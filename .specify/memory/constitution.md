<!--
Sync Impact Report
- Version change: 2.0.0 -> 2.1.0
- Modified principles:
  - I. Idioma (normalizacao de linguagem normativa em portugues)
  - II. Simplicidade acima de complexidade (normalizacao de linguagem normativa em portugues)
  - III. Offline First (permitir internet somente para APIs de IA/LLM no MVP)
  - IV. Arquitetura preparada para evolucao (normalizacao de linguagem normativa em portugues)
  - V. Experiencia do Usuario (normalizacao de linguagem normativa em portugues)
  - VI. Dados e Persistencia (normalizacao de linguagem normativa em portugues)
  - VII. Testabilidade (normalizacao de linguagem normativa em portugues)
  - VIII. Inteligencia Artificial (normalizacao de linguagem normativa em portugues)
  - IX. MVP Primeiro (normalizacao de linguagem normativa em portugues)
  - XI. Gerenciamento de Estado (normalizacao de linguagem normativa em portugues)
  - XII. Portoes de Qualidade (normalizacao de linguagem normativa em portugues)
- Added sections:
  - none
- Removed sections:
  - none
- Templates requiring updates:
  - updated: none
  - pending: none
- Follow-up TODOs:
  - none
-->

# Constitution do Contador de Calorias Mobile

## Core Principles

### I. Idioma
Todos os arquivos em `specs/**` DEVEM ser escritos integralmente em portugues do Brasil,
incluindo `specification.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`,
`quickstart.md`, contratos, ADRs e qualquer outro artefato de especificacao.

Racional: as especificacoes precisam ser acessiveis e compreensiveis para todas as pessoas do
projeto, reduzindo ambiguidades e retrabalho.

### II. Simplicidade acima de complexidade
Cada funcionalidade DEVE adotar a solucao mais simples capaz de atender ao requisito.
Abstracoes prematuras, arquiteturas excessivamente complexas, dependencias desnecessarias e
padroes sofisticados sem beneficio claro sao proibidos no MVP. Toda nova dependencia DEVE
ter justificativa explicita no plano tecnico.

Racional: simplicidade acelera entregas, melhora manutencao e reduz risco de regressao.

### III. Offline First
O aplicativo DEVE funcionar integralmente sem conexao com a internet para as funcionalidades
essenciais do MVP.

A aplicacao PODE depender de internet apenas quando consumir APIs externas relacionadas a IA
e LLM, de forma pontual e explicitamente documentada no `plan.md`.

Qualquer dependencia de internet fora desse escopo NAO DEVE ser introduzida no MVP.

Racional: o valor central do produto depende de uso rapido e confiavel em qualquer contexto.

### IV. Arquitetura preparada para evolucao
O codigo DEVE ser organizado em camadas claras (`presentation`, `application`, `domain`,
`infrastructure`) ou estrutura equivalente aprovada no plano tecnico. A logica de negocio
DEVE permanecer desacoplada de widgets Flutter, mecanismos de armazenamento, APIs externas e
mecanismos de IA.

Racional: separacao de responsabilidades facilita evolucao, testes e substituicao de
tecnologias.

### V. Experiencia do Usuario
Registrar uma refeicao DEVE exigir o menor numero possivel de interacoes. A interface DEVE
ser limpa, intuitiva, responsiva, visualmente agradavel e consistente. Estados vazios,
carregamento e erro DEVEM ser tratados explicitamente.

Racional: o sucesso do produto depende da velocidade de uso e da clareza da experiencia.

### VI. Dados e Persistencia
O modelo de dados DEVE priorizar clareza e simplicidade. O armazenamento inicial PODE ser em
memoria ou local simples, desde que as decisoes de persistencia considerem migracao futura
para sincronizacao em nuvem.

Racional: preservar simplicidade inicial sem bloquear evolucao futura.

### VII. Testabilidade
Toda regra de negocio relevante DEVE ser automatizavel em testes. Logica de negocio em
widgets Flutter NAO DEVE ser introduzida. A estrategia de testes DEVE priorizar calculos,
manipulacao de refeicoes, agregacoes, validacoes e persistencia.

Racional: testar regras centrais previne regressao funcional e aumenta confianca nas
entregas.

### VIII. Inteligencia Artificial
Integracoes com IA sao funcionalidades futuras. O sistema DEVE ser projetado para permitir,
no futuro, interpretacao de texto livre, extracao automatica de alimentos, estimativa
automatica de calorias, reconhecimento por voz e reconhecimento por imagem. Funcionalidades
de IA NAO DEVEM aumentar a complexidade do MVP.

Racional: evoluir com seguranca sem comprometer foco e prazo da versao inicial.

### IX. MVP Primeiro
O projeto DEVE evoluir incrementalmente. Cada feature DEVE entregar valor isolado, ser
utilizavel, ter criterios de aceite claros e permitir implementacao e validacao
independentes. O sucesso inicial DEVE ser medido por simplicidade, velocidade de uso,
estabilidade e clareza da interface, e nao pela quantidade de funcionalidades.

Racional: entregas pequenas e validaveis maximizam aprendizado e reduzem risco.

### X. Padroes Flutter e Dart
O app DEVE seguir as convencoes oficiais de Flutter e Dart.

Codigo Flutter DEVE priorizar:

- widgets pequenos e composiveis;
- separacao clara entre UI e logica de negocio;
- modelos imutaveis quando pratico;
- decisoes explicitas de gerenciamento de estado em `plan.md`;
- Material 3 como base padrao de design;
- nenhuma regra de negocio dentro de widgets.

Codigo Dart DEVE priorizar:

- null safety;
- nomenclatura clara;
- funcoes pequenas;
- tipos explicitos em APIs publicas;
- construtores `const` sempre que aplicavel;
- formatacao com `dart format`;
- analise estatica com `flutter analyze`.

Racional: praticas consistentes de Flutter/Dart reduzem acoplamento da UI, melhoram
manutenibilidade e tornam a base de codigo mais facil de evoluir.

### XI. Gerenciamento de Estado
O gerenciamento de estado DEVE ser escolhido de forma intencional e justificado em
`plan.md`.

Para o MVP, a abordagem viavel mais simples DEVE ser preferida. Bibliotecas de
gerenciamento de estado mais complexas DEVEM ser introduzidas apenas quando houver beneficio
claro.

Estado de UI, estado de aplicacao e regras de dominio DEVEM permanecer conceitualmente
separados.

Racional: gerenciamento de estado e uma fonte comum de complexidade desnecessaria em projetos
Flutter.

### XII. Portoes de Qualidade
Antes de considerar uma funcionalidade concluida, o projeto DEVE passar por:

- `dart format`;
- `flutter analyze`;
- testes automatizados relevantes para a funcionalidade;
- validacao manual contra criterios de aceite.

Racional: portoes de qualidade previnem regressoes simples e mantem o MVP estavel.

## Diretrizes Tecnicas e de Produto

- A versao inicial foca em registrar refeicoes rapidamente e acompanhar calorias diarias.
- Decisoes de arquitetura e produto DEVEM preservar simplicidade operacional para o usuario.
- Adocao de novas tecnologias DEVE provar ganho concreto para o problema atual.

## Processo Obrigatorio de Desenvolvimento

Toda nova funcionalidade DEVE seguir esta ordem:

1. Specification
2. Clarification (quando necessario)
3. Plan
4. Tasks
5. Implementacao
6. Testes
7. Revisao

Nenhuma implementacao pode comecar sem especificacao aprovada.

## Governance

Esta constituicao prevalece sobre praticas conflitantes em artefatos de planejamento e
execucao. Todo plano, lista de tarefas e revisao DEVE demonstrar conformidade explicita com
os principios acima.

Emendas DEVEM incluir motivacao, impacto nos processos existentes e atualizacao de artefatos
afetados. O versionamento segue SemVer:

- MAJOR: remocao ou redefinicao incompativel de principios ou governanca.
- MINOR: novo principio, nova secao obrigatoria, ou expansao material de regras.
- PATCH: clarificacoes editoriais sem mudanca de obrigatoriedade.

Compliance review DEVE acontecer em todo PR por meio de checklist de aderencia
constitucional e durante a elaboracao de `plan.md` (Constitution Check).

**Version**: 2.1.0 | **Ratified**: 2026-06-15 | **Last Amended**: 2026-06-15
