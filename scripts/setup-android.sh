#!/usr/bin/env bash
set -euo pipefail

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
TMPDIR=$(mktemp -d)

echo "Usando ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
mkdir -p "$ANDROID_SDK_ROOT"

cd "$TMPDIR"

echo "Baixando commandlinetools (candidatos)..."

cmd_candidates=(
  "commandlinetools-linux-latest.zip"
  "commandlinetools-linux-9477386_latest.zip"
  "commandlinetools-linux-9123335_latest.zip"
)
download_ok=0
for name in "${cmd_candidates[@]}"; do
  url="https://dl.google.com/android/repository/$name"
  echo "Tentando: $url"
  if command -v curl >/dev/null 2>&1; then
    if curl -fSL "$url" -o commandlinetools.zip; then
      download_ok=1
      break
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q -O commandlinetools.zip "$url"; then
      download_ok=1
      break
    fi
  else
    echo "Instale curl ou wget e rode novamente." >&2
    exit 1
  fi
  echo "Falha ao baixar $name — tentando próximo candidato..."
  rm -f commandlinetools.zip || true
done

if [ "$download_ok" -ne 1 ]; then
  echo "Não foi possível baixar commandlinetools automaticamente. Baixe manualmente de https://developer.android.com/studio#command-line-tools-only" >&2
  exit 1
fi

echo "Extraindo commandlinetools..."
if command -v unzip >/dev/null 2>&1; then
  unzip -q commandlinetools.zip
else
  echo "Instale 'unzip' e rode o script novamente." >&2
  exit 1
fi

# Local destino final
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

# Detectar pasta extraída (pode ser cmdline-tools ou cmdline-tools/latest)
if [ -d cmdline-tools ]; then
  SRC_DIR="cmdline-tools"
else
  # encontrar qualquer diretório que contenha 'cmdline-tools'
  SRC_DIR=$(find . -maxdepth 2 -type d -name 'cmdline-tools*' | head -n 1 || true)
fi

if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
  echo "Não foi encontrada a pasta cmdline-tools após extração." >&2
  ls -la
  exit 1
fi

DEST="$ANDROID_SDK_ROOT/cmdline-tools/latest"
mkdir -p "$DEST"

echo "Copiando $SRC_DIR -> $DEST"
if command -v rsync >/dev/null 2>&1; then
  rsync -a "$SRC_DIR/" "$DEST/"
else
  cp -a "$SRC_DIR/." "$DEST/"
fi

# remover temporários
cd ~
rm -rf "$TMPDIR"

# Atualizar PATH temporário para usar sdkmanager
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

echo "Instalando componentes Android via sdkmanager (platform-tools, emulator, platform android-33, system-image)..."
if command -v sdkmanager >/dev/null 2>&1; then
  # pacotes recomendados para Flutter
  PKGS=(
    "platform-tools"
    "emulator"
    "platforms;android-33"
    "build-tools;36.0.0"
    "system-images;android-33;google_apis;x86_64"
  )
  for p in "${PKGS[@]}"; do
    echo "Instalando: $p"
    sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "$p" || true
  done
  # aceitar licenças (alguns pacotes pedem confirmação)
  yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses || true
else
  echo "sdkmanager não encontrado após copiar cmdline-tools. Verifique $ANDROID_SDK_ROOT/cmdline-tools/latest/bin" >&2
fi

# Garantir platform-tools está presente
if [ -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
  echo "platform-tools instalados."
fi

# Criar AVD (remoção se já existir)
AVD_NAME="pixel_33_api"
if command -v avdmanager >/dev/null 2>&1; then
  echo "Criando/atualizando AVD '$AVD_NAME'..."
  # remover AVD existente com mesmo nome
  if [ -d "$HOME/.android/avd/$AVD_NAME.avd" ]; then
    echo "AVD existente encontrado — removendo..."
    rm -rf "$HOME/.android/avd/$AVD_NAME.avd" || true
    rm -f "$HOME/.android/avd/$AVD_NAME.ini" || true
  fi
  printf "no\n" | avdmanager create avd -n "$AVD_NAME" -k "system-images;android-33;google_apis;x86_64" --force || true
else
  echo "avdmanager não disponível — a criação automática do AVD será pulada." >&2
fi

cat <<EOF
Instalação concluída (sem sudo).
Para usar imediatamente no shell atual, rode:

export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/emulator:\$PATH"

Verifique com:
  flutter doctor -v
  adb --version
  sdkmanager --version
  avdmanager --version

Para iniciar o emulador (headless):
  $ANDROID_SDK_ROOT/emulator/emulator -avd $AVD_NAME -no-window -no-audio &

Observações:
- O script copia os commandlinetools para 'cmdline-tools/latest' para manter compatibilidade com ferramentas.
- Se alguma etapa falhar, verifique os logs e rode os comandos manualmente.
EOF
