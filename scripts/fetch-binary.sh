#!/usr/bin/env bash
# Скачивает официальный бинарь OpenCode V2 для текущей платформы в bin/.
#
# Usage:
#   bash scripts/fetch-binary.sh [VERSION]
#
# VERSION — версия upstream (например 2.2.6). Если не указана — берётся последняя V2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

VER="${1:-}"
if [ -z "$VER" ]; then
  VER="$(latest_v2 || true)"
fi
VER="${VER#v}"
if ! is_version "$VER"; then
  echo "Нужна версия OpenCode V2 в формате 2.2.6 (получено: ${VER:-пусто})." >&2
  exit 1
fi

OS="$(uname -s)"
ARCH="$(uname -m)"
MUSL=""
if [ "$OS" = "Linux" ]; then
  if ldd --version 2>&1 | grep -qi musl || ls /lib/ld-musl-* >/dev/null 2>&1; then
    MUSL="-musl"
  fi
fi

case "$OS:$ARCH" in
  Linux:x86_64|Linux:amd64)   ASSET="opencode-linux-x64${MUSL}.tar.gz";  EXE="opencode" ;;
  Linux:aarch64|Linux:arm64)  ASSET="opencode-linux-arm64${MUSL}.tar.gz"; EXE="opencode" ;;
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
tmp=""
trap 'rm -rf -- "$DL"; if [ -n "${tmp:-}" ]; then rm -f -- "$tmp"; fi' EXIT

echo "== OpenCode v$VER: $ASSET =="
curl -fL --retry 3 --proto '=https' --proto-redir '=https' -o "$DL/$ASSET" "$BASE/$ASSET"
curl -fL --retry 3 --proto '=https' --proto-redir '=https' -o "$DL/SHA256SUMS" "$BASE/SHA256SUMS"
verify_sha256 "$DL/$ASSET" "$ASSET" "$DL/SHA256SUMS"

case "$ASSET" in
  *.tar.gz) tar -xzf "$DL/$ASSET" -C "$DL" ;;
  *.zip)
    if command -v unzip >/dev/null 2>&1; then
      unzip -oq "$DL/$ASSET" -d "$DL"
    elif command -v python3 >/dev/null 2>&1; then
      python3 -m zipfile -e "$DL/$ASSET" "$DL"
    else
      echo "Для распаковки zip нужен unzip или python3." >&2
      exit 1
    fi
    ;;
esac

SRC="$(find "$DL" -type f -name "$EXE" | head -n1)"
if [ -z "$SRC" ]; then
  echo "В архиве $ASSET не найден $EXE" >&2
  exit 1
fi

mkdir -p "$ROOT/bin"
tmp="$ROOT/bin/.$EXE.tmp.$$"
cp "$SRC" "$tmp"
chmod +x "$tmp"
mv -f "$tmp" "$ROOT/bin/$EXE"
tmp=""

echo "Готово: bin/$EXE"
"$ROOT/bin/$EXE" --version
