#!/usr/bin/env bash
# Скачивает официальный бинарь OpenCode V2 для текущей платформы в bin/.
#
# Usage:
#   bash scripts/fetch-binary.sh [VERSION]
#
# VERSION — тег upstream (например 2.2.6). Если не указан — берётся последний V2.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="anomalyco/opencode"

VER="${1:-}"
if [ -z "$VER" ]; then
  VER="$(curl -fsSL "https://api.github.com/repos/$UPSTREAM/releases?per_page=50" \
    | grep -o '"tag_name": *"v2\.[^"]*"' \
    | head -n1 \
    | sed -E 's/.*"(v2\.[^"]*)"/\1/' || true)"
fi
VER="${VER#v}"
if [ -z "$VER" ]; then
  echo "Не удалось определить версию OpenCode V2. Укажи её явно: bash scripts/fetch-binary.sh 2.2.6" >&2
  exit 1
fi

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS:$ARCH" in
  Linux:x86_64|Linux:amd64)   ASSET="opencode-linux-x64.tar.gz";  EXE="opencode" ;;
  Linux:aarch64|Linux:arm64)  ASSET="opencode-linux-arm64.tar.gz"; EXE="opencode" ;;
  Darwin:x86_64|Darwin:amd64) ASSET="opencode-darwin-x64.zip";     EXE="opencode" ;;
  Darwin:arm64|Darwin:aarch64) ASSET="opencode-darwin-arm64.zip";  EXE="opencode" ;;
  MINGW*:x86_64|MSYS*:x86_64|CYGWIN*:x86_64) ASSET="opencode-windows-x64.zip"; EXE="opencode.exe" ;;
  MINGW*:aarch64|MSYS*:aarch64|CYGWIN*:aarch64) ASSET="opencode-windows-arm64.zip"; EXE="opencode.exe" ;;
  *)
    echo "Неизвестная платформа: $OS $ARCH" >&2
    exit 1
    ;;
esac

BASE="https://github.com/$UPSTREAM/releases/download/v$VER"
DL="$(mktemp -d)"
trap 'rm -rf "$DL"' EXIT

echo "== OpenCode v$VER: $ASSET =="
curl -fL --retry 3 -o "$DL/$ASSET" "$BASE/$ASSET"

case "$ASSET" in
  *.tar.gz) tar -xzf "$DL/$ASSET" -C "$DL" ;;
  *.zip)
    command -v unzip >/dev/null 2>&1 || { echo "unzip не найден" >&2; exit 1; }
    unzip -oq "$DL/$ASSET" -d "$DL"
    ;;
esac

SRC="$(find "$DL" -type f -name "$EXE" | head -n1)"
if [ -z "$SRC" ]; then
  echo "В архиве $ASSET не найден $EXE" >&2
  exit 1
fi

mkdir -p "$ROOT/bin"
cp "$SRC" "$ROOT/bin/$EXE"
chmod +x "$ROOT/bin/$EXE"
echo "Готово: bin/$EXE"
"$ROOT/bin/$EXE" --version
