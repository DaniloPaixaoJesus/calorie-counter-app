# Nutrity App

Aplicativo Flutter do Calorie Counter. O app registra refeicoes, calcula o total diario de calorias, transcreve audio localmente e chama o BFF para estimar calorias com IA.

## Requisitos

- Flutter/Dart configurados
- Android SDK para testar em dispositivo Android
- BFF publicado ou local disponivel para estimativas de IA

## Executar

Na pasta `app/`:

```bash
flutter pub get
flutter run
```

Para escolher um dispositivo:

```bash
flutter devices
flutter run -d <device-id>
```

## Configuracao do BFF

O app usa `BffAiAdapter` para chamar o endpoint de estimativa:

```text
POST /bff-service/ai/meal-estimates
```

As configuracoes podem ser sobrescritas via `--dart-define`:

```bash
flutter run \
  --dart-define=NUTRITY_BFF_MEAL_ESTIMATE_URL=https://seu-bff/bff-service/ai/meal-estimates \
  --dart-define=NUTRITY_BFF_API_KEY=<sua-chave>
```

Em desenvolvimento, existe um valor padrao apontando para o Cloud Run do projeto.

## Funcionalidades

- Home com total de calorias por data.
- Navegacao por dia anterior, proximo dia e hoje.
- Registro de refeicao por texto.
- Registro de refeicao por audio com `speech_to_text`.
- Estimativa de calorias via BFF.
- Limite local de 60 estimativas por dia, com contador decrescente.
- Aviso quando restam apenas 10 estimativas no dia.
- Aviso de baixa confianca da IA em formato warning.
- Revisao da estimativa antes de salvar.
- Edicao de refeicao salva: detalhes completos, observacao e opcao de editar descricao/calorias.
- Remocao de refeicao com confirmacao.
- Persistencia local SQLite.

## Build APK

```bash
flutter build apk --release
```

APK gerado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Instalacao via ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Testes e qualidade

```bash
dart format lib test
flutter analyze
flutter test
```

## Estrutura

```text
lib/
├── design_system/       # tokens, breakpoints e registro de icon keys
├── features/home/       # Home, adicionar, revisar, editar e widgets
├── models/              # modelo Meal
├── services/
│   ├── ai_adapter/      # contrato, mock e adapter BFF
│   ├── audio_transcription/
│   └── repository/      # SQLite e memoria para testes
├── themes/
└── utils/
```

## Observacoes de desenvolvimento

- A chave do BFF fica embutida no app nesta fase de desenvolvimento.
- Para producao, substitua por uma estrategia de seguranca mais robusta.
- O limite de 60 estimativas por dia e local ao app nesta versao.
