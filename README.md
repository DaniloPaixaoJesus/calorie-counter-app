# Calorie Counter App

Aplicativo Flutter para registrar refeicoes e acompanhar o total diario de calorias. O MVP permite adicionar refeicoes por texto ou audio, estimar calorias com uma camada de IA mockada, revisar a sugestao antes de salvar, navegar por datas e remover registros com confirmacao.

## Visao Geral

O projeto esta organizado como um monorepo. A aplicacao principal fica em `app/`, enquanto as especificacoes funcionais ficam em `specs/`.

O app foi desenhado para funcionar inicialmente sem backend e sem autenticacao. Os dados sao mantidos em memoria durante a execucao do app, com a arquitetura preparada para trocar a persistencia e a integracao real de IA no futuro.

## Funcionalidades

- Home com total de calorias da data selecionada.
- Lista de refeicoes filtrada por dia.
- Estado vazio especifico para datas sem refeicoes.
- Navegacao entre dia anterior, proximo dia e hoje.
- Adicao de refeicao por texto.
- Adicao de refeicao por audio com transcricao on-device via `speech_to_text`.
- Estimativa calorica por IA usando adaptador mock no MVP.
- Revisao da estimativa antes de salvar.
- Edicao de descricao e calorias antes da confirmacao.
- Indicacao de confianca baixa da IA.
- Icone de refeicao inferido pela IA.
- Remocao de refeicao com dialogo de confirmacao.
- Tema visual baseado em Material 3.

## Stack

- Flutter
- Dart
- Provider para estado da UI
- Material 3
- `speech_to_text` para entrada por audio
- `intl` para formatacao de datas
- `uuid` para identificadores de refeicao
- `flutter_test` para testes unitarios e de widget

## Estrutura

```text
.
├── app/                         # Aplicacao Flutter
│   ├── lib/
│   │   ├── design_system/       # Tokens visuais, breakpoints e registro de icones
│   │   ├── features/home/       # Telas, widgets e ViewModel da feature principal
│   │   ├── models/              # Entidades do dominio
│   │   ├── services/            # IA, transcricao de audio, speech e repositorio
│   │   ├── themes/              # Tema Material 3
│   │   └── utils/               # Utilitarios de data e icones
│   ├── test/                    # Testes unitarios e de widget
│   └── pubspec.yaml
├── docs/                        # Guias de ambiente
├── scripts/                     # Scripts auxiliares
└── specs/                       # Especificacoes, planos, contratos e tarefas
```

## Como Rodar

Entre na pasta da aplicacao Flutter:

```bash
cd app
flutter pub get
flutter run
```

Para rodar em um dispositivo especifico:

```bash
flutter devices
flutter run -d <device-id>
```

Mais detalhes de ambiente estao em `docs/setup.md`.

## Testes

Na pasta `app/`, execute:

```bash
flutter test
```

Para analise estatica:

```bash
flutter analyze
```

Para formatar o codigo:

```bash
dart format .
```

## Arquitetura

O app usa uma separacao simples entre UI, estado, dominio e servicos.

- `HomeViewModel` concentra o estado da Home, estimativas, navegacao por data, total diario e remocao.
- `Meal` representa uma refeicao com descricao, calorias, data/hora, origem, confianca da IA, nota e chave de icone.
- `InMemoryRepository` armazena refeicoes em memoria no MVP.
- `AiAdapter` define o contrato de estimativa calorica.
- `AiAdapterMock` simula a IA com palavras-chave e retorna calorias, observacao, confianca e icone.
- `AudioTranscriptionAdapter` define o contrato de transcricao.
- `OfflineAudioTranscriptionAdapter` usa reconhecimento de voz local/on-device.

## Especificacoes

As principais especificacoes do produto estao em:

- `specs/001-home-adicionar-refeicao-ia/`: Home e adicionar refeicao com estimativa por IA.
- `specs/002-remover-refeicao-data/`: Remocao de refeicao e navegacao por data.
- `specs/003-design-system-e-layout-material3/`: Design System e layout Material 3.

## Status Atual

O projeto esta em fase de MVP. A UI principal, fluxo de adicao, estimativa mockada, navegacao por data, remocao e testes ja existem. Persistencia local definitiva, backend, autenticacao, sincronizacao em nuvem e integracao com IA real ainda estao fora do escopo atual.

## Setup Android

Para preparar um ambiente Android headless, existe o script:

```bash
chmod +x scripts/setup-android.sh
./scripts/setup-android.sh
```

Depois, exporte as variaveis indicadas pelo proprio script e confirme o ambiente com:

```bash
flutter doctor -v
adb devices
```
