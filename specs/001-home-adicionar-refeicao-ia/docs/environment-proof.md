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
