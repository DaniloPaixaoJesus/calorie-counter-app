# Guia de configuração do ambiente — Calorie Counter App

Este documento descreve os passos para preparar um ambiente de desenvolvimento para a aplicação Flutter MVP.

AVISO: Instalar ferramentas de sistema (Flutter, Android SDK, JDK) pode requerer permissões de administrador. Siga as instruções do seu sistema operacional.

## Verificações rápidas

Execute no terminal:

```bash
flutter --version
flutter doctor -v
java -version
adb --version
```

## 1) Instalar Flutter SDK

- Linux/macOS: siga https://docs.flutter.dev/get-started/install
- Windows: siga https://docs.flutter.dev/get-started/install/windows

Resumo dos passos (Linux):

```bash
# baixar e extrair o SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_stable.tar.xz
tar xf flutter_linux_stable.tar.xz
# adicionar ao PATH temporariamente
export PATH="$PWD/flutter/bin:$PATH"
# verificar
flutter --version
flutter doctor
```

Observação: no nosso repositório usamos uma cópia local do Flutter em `tools/flutter` para builds reproduzíveis. Se quiser usar essa cópia (já baixada no ambiente de desenvolvimento), adicione ao PATH:

```bash
export PATH="$PWD/tools/flutter/bin:$PATH"
```

## Monorepo: estrutura de pastas

Este repositório usa um layout de monorepo com os seguintes diretórios principais:

- `/app` — aplicação cliente Flutter (onde ficarão `pubspec.yaml`, `lib/`, `android/`, `ios/`, etc.)
- `/bff` — backend BFF (ainda não criado)

Quando executar comandos do Flutter para desenvolver/rodar o app, mude para o diretório `/app`:

```bash
cd app
flutter pub get
flutter run -d emulator-5554
```

## 2) Instalar Java JDK

- Recomendado: OpenJDK 17 ou versão compatível com o SDK Android.

Exemplo (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install openjdk-17-jdk
java -version
```

## 3) Android SDK / Android Studio / AVD

 - Instale o Android Studio (recomendado) e use o AVD Manager para criar um emulador.
 - Alternativamente (headless), use o script `scripts/setup-android.sh` fornecido neste repositório para instalar `cmdline-tools`, `platform-tools`, `emulator`, plataformas e imagens, e criar um AVD x86 compatível com Flutter.

 Passos rápidos (headless):

 ```bash
 # conceda permissão de execução e execute (não requer sudo):
 chmod +x scripts/setup-android.sh
 ./scripts/setup-android.sh

 # após a execução, adicione ao shell (temporário para sessão atual):
 export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
 export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/emulator:$PATH"

 # verifique:
 flutter doctor -v
 adb --version
 sdkmanager --version
 avdmanager --version
 ```

 Se preferir fazer manualmente, instale `commandlinetools` a partir de https://developer.android.com/studio#command-line-tools-only, extraia para `$HOME/Android/Sdk/cmdline-tools/latest`, e então use `sdkmanager` para instalar pacotes (veja o script para exemplo concreto).

## 4) Verificar conectividade ADB

```bash
adb devices
```

## 5) Diagnóstico final

Rode `flutter doctor -v` e resolva mensagens indicadas (ferramentas ausentes, licenças, etc.).

## 6) Criar AVD (Android Emulator)

 Usando Android Studio (GUI):

 - Abra Android Studio → AVD Manager → Criar Virtual Device → Escolha um dispositivo (por ex. Pixel 4)
 - Selecione uma imagem x86 (com Google APIs) compatível (recomendado: api 33 / android-33 x86_64)
 - Finalize e inicie o AVD

 Usando linha de comando (exemplo de criação automatizada):

 ```bash
 # exemplo (cria AVD chamado pixel_33_api)
 avdmanager create avd -n "pixel_33_api" -k "system-images;android-33;google_apis;x86_64" --force
 $ANDROID_SDK_ROOT/emulator/emulator -avd pixel_33_api -no-window -no-audio &
 adb wait-for-device
 adb shell getprop sys.boot_completed | grep 1
 ```

---
Salve evidência dos passos concluídos no repositório em `specs/001-home-adicionar-refeicao-ia/docs/environment-proof.md` quando terminar.
