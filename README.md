# Calorie Counter App

Aplicativo Flutter para registrar refeicoes e acompanhar o total diario de calorias. O MVP permite adicionar refeicoes por texto ou audio, estimar calorias via BFF com IA, revisar a sugestao antes de salvar, editar registros, navegar por datas e remover refeicoes com confirmacao.

## Visao Geral

O projeto esta organizado como um monorepo. A aplicacao principal fica em `app/`, o backend BFF Java fica em `bff/`, e as especificacoes funcionais ficam em `specs/`.

O app usa persistencia local SQLite e consome o BFF publicado no Google Cloud Run para estimativas de calorias. O BFF protege as rotas de IA com `X-App-Api-Key` e integra providers de IA por adapters.

## Funcionalidades

- Home com total de calorias da data selecionada.
- Lista de refeicoes filtrada por dia.
- Estado vazio especifico para datas sem refeicoes.
- Navegacao entre dia anterior, proximo dia e hoje.
- Adicao de refeicao por texto.
- Adicao de refeicao por audio com transcricao on-device via `speech_to_text`.
- Estimativa calorica por IA usando adaptador mock no MVP.
- Estimativa calorica por IA via BFF Java e OpenAI GPT.
- Revisao da estimativa antes de salvar.
- Edicao de descricao e calorias antes da confirmacao.
- Edicao de refeicao salva, com tela de detalhes e opcao de alterar descricao/calorias.
- Indicacao de confianca baixa da IA.
- Limite local de 60 estimativas por dia, com contador decrescente e aviso nas ultimas 10.
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
- `sqflite` para persistencia local
- `flutter_test` para testes unitarios e de widget
- Java 21 + Spring Boot no BFF

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
├── bff/                         # Backend for Frontend Java/Spring Boot
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

Para gerar APK release:

```bash
cd app
flutter build apk --release
```

O APK fica em `app/build/app/outputs/flutter-apk/app-release.apk`.

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
- `SqliteMealRepository` armazena refeicoes localmente no app.
- `AiAdapter` define o contrato de estimativa calorica.
- `BffAiAdapter` chama o BFF Java para estimativas reais.
- `AiAdapterMock` continua disponivel para testes e desenvolvimento isolado.
- `AudioTranscriptionAdapter` define o contrato de transcricao.
- `OfflineAudioTranscriptionAdapter` usa reconhecimento de voz local/on-device.

## Especificacoes

As principais especificacoes do produto estao em:

- `specs/001-home-adicionar-refeicao-ia/`: Home e adicionar refeicao com estimativa por IA.
- `specs/002-remover-refeicao-data/`: Remocao de refeicao e navegacao por data.
- `specs/003-design-system-e-layout-material3/`: Design System e layout Material 3.

## Status Atual

O projeto esta em fase de MVP. A UI principal, fluxo de adicao, edicao, estimativa via BFF, persistencia local SQLite, navegacao por data, remocao e testes ja existem. Autenticacao de usuario, sincronizacao em nuvem e reconhecimento por imagem ainda estao fora do escopo atual.

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
