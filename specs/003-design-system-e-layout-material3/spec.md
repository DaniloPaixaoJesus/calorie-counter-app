# Especificação: Design System e Layout Material 3

**Feature**: 003-design-system-e-layout-material3
**Autor**: GitHub Copilot
**Status**: Em elaboração
**Data**: 2026-06-16

## 1. Visão Geral

Esta especificação descreve a criação e aplicação de um Design System baseado em Material 3 para padronizar a interface do usuário (UI) e a experiência do usuário (UX) do aplicativo. O objetivo é modernizar o visual, garantir consistência e melhorar a usabilidade, utilizando como inspiração as imagens fornecidas.

A feature foca exclusivamente na camada visual, sem introduzir novas funcionalidades de negócio.

## 2. Requisitos Funcionais (FR)

| ID | Requisito | Detalhes | Prioridade |
|---|---|---|---|
| FR001 | **Navegação Principal** | Implementar uma barra de navegação inferior (`NavigationBar`) com duas abas: "Home" e "Adicionar". | Essencial |
| FR002 | **Tela Home (Lista de Refeições)** | A tela principal deve exibir um card de destaque com o total de calorias do dia e uma lista das refeições registradas. | Essencial |
| FR003 | **Fluxo de Adicionar Refeição** | Ao tocar em "Adicionar", o usuário deve ser apresentado a uma tela de seleção com duas opções: "Digitar texto" e "Gravar áudio". | Essencial |
| FR004 | **Tela de Gravação de Áudio** | A tela de gravação deve mostrar um indicador visual de áudio (onda sonora), um timer regressivo (iniciando em 30s) e um botão para iniciar/parar a gravação. | Essencial |
| FR005 | **Tela de Revisão da Estimativa** | Após a entrada de dados (texto ou áudio), uma tela de revisão deve ser exibida, mostrando a descrição interpretada, a estimativa de calorias, a confiança da IA e a observação. A observação pode incluir notas sobre valores padrão assumidos (ex: "quantidade não informada, assumido 100g"). O usuário pode editar os campos antes de confirmar. | Essencial |
| FR006 | **Navegação entre Datas** | A tela Home deve permitir a navegação para o dia anterior e o dia seguinte de forma simples, através de ícones ou gestos. | Essencial |
| FR007 | **Modal de Confirmação para Remoção** | Ao tentar remover uma refeição, um diálogo modal deve ser exibido, solicitando a confirmação do usuário. O modal deve mostrar os detalhes da refeição a ser removida. | Essencial |
| FR008 | **Estado Vazio Amigável** | A lista de refeições na tela Home, quando não houver itens para o dia selecionado, deve exibir uma mensagem amigável e um convite visual para adicionar a primeira refeição. | Essencial |
| FR009 | **Seleção de Ícone pela IA** | A IA, ao estimar as calorias, deve retornar uma chave de ícone (ex: `breakfast`, `lunch`) baseada na análise da refeição, incluindo a descrição e o horário do registro. | Essencial |
| FR010 | **Exibição de Ícone na Lista** | A lista de refeições na tela Home deve exibir o ícone correspondente a cada refeição, conforme retornado pela IA ou um ícone padrão. | Essencial |

## 3. Requisitos Não-Funcionais (NFR)

| ID | Requisito | Detalhes | Prioridade |
|---|---|---|---|
| NFR001 | **Consistência Visual (Material 3)** | Todos os componentes, cores, tipografia e espaçamentos devem seguir as diretrizes do Material 3 e do Design System definido. | Essencial |
| NFR002 | **Tema Claro** | O aplicativo deve utilizar um tema claro como padrão, com alto contraste para garantir a legibilidade. | Essencial |
| NFR003 | **Responsividade** | A interface deve se adaptar a diferentes tamanhos de tela (smartphones pequenos e grandes), garantindo que todos os elementos sejam visíveis e utilizáveis. | Essencial |
| NFR004 | **Acessibilidade (A11y)** | Os componentes devem ter áreas de toque adequadas (mínimo 48x48dp), contraste de cores suficiente e ser compatíveis com leitores de tela. | Alta |
| NFR005 | **Performance** | As animações e transições de tela devem ser fluidas (60fps), sem travamentos ou lentidão. | Alta |

## 4. Design System (Componentes e Estilos)

### 4.1. Paleta de Cores

| Nome | Cor (Hex) | Uso |
|---|---|---|
| Primary | `#4CAF50` (Verde) | Destaques, botões principais, card de calorias |
| On Primary | `#FFFFFF` (Branco) | Texto sobre cor primária |
| Secondary | `#FFC107` (Âmbar) | Ações secundárias, avisos |
| Surface | `#FFFFFF` (Branco) | Fundo principal, cards |
| On Surface | `#212121` (Cinza Escuro) | Texto principal |
| On Surface Variant | `#757575` (Cinza Médio) | Texto secundário, descrições |
| Error | `#D32F2F` (Vermelho) | Erros, botões de exclusão |

### 4.2. Tipografia

| Estilo | Fonte | Tamanho | Peso | Uso |
|---|---|---|---|---|
| Display Large | Roboto | 57sp | Bold | Total de calorias |
| Headline Medium | Roboto | 28sp | Bold | Títulos de página |
| Title Large | Roboto | 22sp | Medium | Títulos de seção/card |
| Body Large | Roboto | 16sp | Regular | Corpo de texto, itens de lista |
| Label Large | Roboto | 14sp | Medium | Botões |

### 4.3. Componentes Reutilizáveis

- **Card de Total de Calorias**: Componente de destaque na Home.
- **Item de Lista de Refeição**: Componente para exibir cada refeição com ícone, nome, descrição, e calorias.
- **Botão de Ação Principal**: Botão preenchido (`FilledButton`) para ações como "Confirmar".
- **Botão de Ação Secundária**: Botão de texto (`TextButton`) para ações como "Cancelar".
- **Diálogo de Confirmação**: Modal para ações destrutivas.

## 5. Escopo e Fora do Escopo

### 5.1. No Escopo

- Refatoração visual de todas as telas existentes para usar o novo Design System.
- Criação de componentes reutilizáveis em Flutter.
- Definição do tema do aplicativo (`ThemeData`).
- Modificação do retorno da IA para incluir a chave do ícone, calorias e observações sobre valores assumidos.
- Armazenamento e exibição do ícone da refeição.

### 5.2. Fora do Escopo

- Novas funcionalidades (gráficos, metas, relatórios, gamificação).
- Tema escuro.
- Alterações de backend.
- Calendário mensal complexo para seleção de data.
- Edição do ícone da refeição pelo usuário nesta feature.

## 6. Critérios de Aceite

- Todas as telas refletem o novo Design System inspirado na imagem de referência.
- O aplicativo utiliza componentes e o tema do Material 3.
- A navegação inferior funciona corretamente.
- O fluxo de adicionar refeição (texto e áudio) está visualmente coeso.
- O modal de remoção é exibido conforme o design.
- O estado vazio da lista de refeições é exibido corretamente.
- A estimativa da IA retorna uma chave de ícone válida.
- A refeição salva armazena a chave do ícone.
- A lista de refeições exibe o ícone correto para cada item (ou um ícone padrão se a chave for inválida).
- O app continua funcional em diferentes tamanhos de tela.
- O código está formatado (`dart format`) e sem alertas (`flutter analyze`).

## 7. Anexos e Referências

- Imagens de referência da UI/UX anexadas ao prompt.
- Documentação do Material 3: [https://m3.material.io/](https://m3.material.io/)
- Documentação de Theming em Flutter: [https://docs.flutter.dev/cookbook/design/themes](https://docs.flutter.dev/cookbook/design/themes)
