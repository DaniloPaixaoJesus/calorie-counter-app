# Prova de execução do setup — Fase 0

Data: 2026-06-15

Resumo das ações executadas sem privilégios de administrador (instalação local do Flutter no diretório `tools/flutter`):

- Clone do repositório oficial do Flutter (canal `stable`) para `tools/flutter` — concluído.
- Download do engine/Dart SDK durante a inicialização do Flutter (progresso mostrado abaixo).
- `java -version`: OpenJDK detectado.
- `adb`: não encontrado no PATH.

Trecho do log (download do Dart/engine):

```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0  222M    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
 10  222M   10 23.8M    0     0  10.4M      0  0:00:21  0:00:02  0:00:19 10.4M
 20  222M   20 46.2M    0     0  13.9M      0  0:00:15  0:00:03  0:00:12 13.9M
 31  222M   31 70.2M    0     0  16.3M      0  0:00:13  0:00:04  0:00:09 16.3M
 43  222M   43 96.5M    0     0  18.2M      0  0:00:12  0:00:05  0:00:07 19.9M
 53  222M   53  120M    0     0  19.0M      0  0:00:11  0:00:06  0:00:05 23.7M
 64  222M   64  143M    0     0  19.6M      0  0:00:11  0:00:07  0:00:04 23.8M
 76  222M   76  170M    0     0  20.5M      0  0:00:10  0:00:08  0:00:02 25.0M
 87  222M   87  195M    0     0  20.9M      0  0:00:10  0:00:09  0:00:01 24.9M
100  222M  100  222M    0     0  21.6M      0  0:00:10  0:00:10 --:--:-- 25.2M
```

Saídas detectadas no host durante a verificação:

- `java -version`: OpenJDK 21.0.10 (presente)
- `adb --version`: não encontrado (ausente)

Próximos passos sugeridos (requer interação do usuário / permissões):

1. Instalar `adb` (Android Platform Tools) via gerenciador de pacotes do SO (`sudo apt install adb`) ou instalar Android Studio e as platform tools.
2. Se quiser que eu tente instalar `adb` via apt/sudo e/ou instalar Flutter via `snap`, autorize que eu execute comandos com sudo.
3. Após instalação do Android SDK/ADB, execute `flutter doctor -v` e resolva pendências indicadas (licenças, plugins do Android Studio).

## Re-checagem após instalação do Android Studio

Executado: 2026-06-15 — verificação completa das ferramentas disponíveis no host.

Resumo das saídas detectadas:

- `which flutter`: `/snap/bin/flutter` (instalação via snap detectada)
- `flutter --version`: `Flutter 3.44.2` (canal stable)
- `flutter doctor -v`: mostrou que o Flutter local em `tools/flutter` existe, mas o Android SDK não foi localizado; também reportou faltas para toolchains de Linux (clang, cmake, ninja, GTK dev).
- `java -version`: OpenJDK 21.0.10 (presente)
- `adb --version`: não encontrado (ainda ausente no PATH)
- `sdkmanager`, `avdmanager`, `emulator`: comandos não encontrados no PATH (ferramentas do Android SDK não expostas globalmente)

Trecho relevante do `flutter doctor -v`:

```
[!] Flutter (Channel stable, 3.44.2, on Ubuntu 22.04.5 LTS ...)
  • Flutter version 3.44.2 on channel stable at /home/s017754475/workspace/MY_STUDIES/meu_github/calorie-counter-app/tools/flutter
  ! Warning: `flutter` on your path resolves to /usr/bin/snap, which is not inside your current Flutter SDK checkout at /home/.... Consider adding .../tools/flutter/bin to the front of your path.

[✗] Android toolchain - develop for Android devices
  ✗ Unable to locate Android SDK.
    Install Android Studio ... On first launch it will assist you in installing the Android SDK components.

[✓] Connected device (2 available)
  • Linux (desktop) • linux  • linux-x64
  • Chrome (web)    • chrome • web-javascript

Comandos faltantes detectados:

- `adb`: sugerido `sudo apt install adb`
- `sdkmanager`: sugerido `sudo apt install sdkmanager`
- `avdmanager`: comando não encontrado
- `emulator`: sugerido `sudo apt install google-android-emulator-installer`

Conclusão: o Android Studio foi instalado, porém as ferramentas de linha de comando do SDK (platform-tools, cmdline-tools e emulator) não estão disponíveis globalmente no PATH. Para rodar e emular dispositivos Android via CLI ainda é necessário instalar/ativar o Android SDK (pelo Android Studio ou via sdkmanager) e garantir `adb`, `emulator` e `avdmanager` no PATH.

Próximo passo sugerido: executar a instalação headless das Android CLI tools (platform-tools, cmdline-tools, emulator, system-images) ou abrir o Android Studio e usar o SDK Manager para instalar os componentes e criar um AVD.

## Segunda checagem (após instalar Android Studio)

Executado novamente: 2026-06-15 — saída atualizada das ferramentas:

```
/snap/bin/flutter
Flutter 3.44.2 • channel stable • https://github.com/flutter/flutter.git
[!] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
    • Android SDK at /home/s017754475/Android/Sdk
    • Emulator version 36.6.11.0 (build_id 15507667)
    ✗ cmdline-tools component is missing.
      Try installing or updating Android Studio.
    ✗ Android license status unknown.
      Run `flutter doctor --android-licenses` to accept the SDK licenses.

! Doctor found issues in 1 category.

Comandos ausentes detectados:
- `adb`: não encontrado
- `sdkmanager`: não encontrado
- `avdmanager`: não encontrado
- `emulator`: não encontrado
```

Observação: o Android Studio foi instalado, o SDK principal foi criado em `/home/s017754475/Android/Sdk`, porém os `cmdline-tools` (necessários para `sdkmanager`, `avdmanager`, `emulator`) não estão completos/ativados no PATH. Para finalizar o setup headless, execute os passos de instalação do `cmdline-tools` e do `platform-tools` (conforme instruções anteriores).
