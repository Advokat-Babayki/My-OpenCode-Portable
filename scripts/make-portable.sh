#!/usr/bin/env bash
# Собирает переносимые бандлы OpenCode V2 для Windows и Linux из официальных бинарей.
#
# Usage:
#   bash scripts/make-portable.sh [VERSION]
#
# VERSION — версия upstream (например 2.2.6). Если не указана — берётся
# OPENCODE_VERSION из репозитория, иначе последняя V2.
# Результат: release/opencode-portable-windows-x64.zip,
#            release/opencode-portable-linux-x64.tar.gz
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

VER="${1:-}"
if [ -z "$VER" ] && [ -s "$ROOT/OPENCODE_VERSION" ]; then
  VER="$(cat "$ROOT/OPENCODE_VERSION")"
fi
if [ -z "$VER" ]; then
  VER="$(latest_v2 || true)"
fi
VER="${VER#v}"
if ! is_version "$VER"; then
  echo "Нужна версия OpenCode V2 в формате 2.2.6 (получено: ${VER:-пусто})." >&2
  exit 1
fi

for c in curl tar awk find; do
  command -v "$c" >/dev/null 2>&1 || { echo "Не найден $c" >&2; exit 1; }
done
if ! command -v unzip >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo "Для распаковки zip нужен unzip или python3." >&2
  exit 1
fi
if ! command -v zip >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo "Для создания zip нужен zip или python3." >&2
  exit 1
fi

BASE="https://github.com/$UPSTREAM/releases/download/v$VER"
DL="$(mktemp -d)"
OUT="$ROOT/release"
STAGE="$OUT/.build"
mkdir -p "$STAGE"
trap 'rm -rf -- "$DL" "$STAGE"' EXIT

echo "== opencode-portable $VER =="
echo "== Downloading upstream binaries =="
curl -fL --retry 3 --proto '=https' --proto-redir '=https' -o "$DL/win.zip" "$BASE/opencode-windows-x64.zip"
curl -fL --retry 3 --proto '=https' --proto-redir '=https' -o "$DL/linux.tgz" "$BASE/opencode-linux-x64.tar.gz"
curl -fL --retry 3 --proto '=https' --proto-redir '=https' -o "$DL/SHA256SUMS" "$BASE/SHA256SUMS"
verify_sha256 "$DL/win.zip" "opencode-windows-x64.zip" "$DL/SHA256SUMS"
verify_sha256 "$DL/linux.tgz" "opencode-linux-x64.tar.gz" "$DL/SHA256SUMS"

mkdir -p "$DL/win" "$DL/linux"
if command -v unzip >/dev/null 2>&1; then
  unzip -oq "$DL/win.zip" -d "$DL/win"
else
  python3 -m zipfile -e "$DL/win.zip" "$DL/win"
fi
tar -xzf "$DL/linux.tgz" -C "$DL/linux"

WIN_BIN="$(find "$DL/win" -type f -name opencode.exe | head -n1)"
LINUX_BIN="$(find "$DL/linux" -type f -name opencode | head -n1)"
if [ -z "$WIN_BIN" ] || [ -z "$LINUX_BIN" ]; then
  echo "В архивах upstream не найден бинарь opencode." >&2
  exit 1
fi

WIN_BUILD="$DL/win-build"
LINUX_BUILD="$DL/linux-build"
WIN_DIR="$WIN_BUILD/opencode-portable-windows-x64"
LINUX_DIR="$LINUX_BUILD/opencode-portable-linux-x64"
mkdir -p "$WIN_BUILD" "$LINUX_BUILD"

make_common() {
  local dir="$1" launcher="$2" src_bin="$3" bin_name="$4"
  mkdir -p "$dir/config" "$dir/data" "$dir/cache" "$dir/state" "$dir/tmp" "$dir/bin" "$dir/scripts"
  for sub in agents commands plugins skills; do
    mkdir -p "$dir/config/$sub"
    if [ -d "$ROOT/config/$sub" ]; then
      cp -a "$ROOT/config/$sub/." "$dir/config/$sub/"
    fi
  done
  for f in opencode.json AGENTS.md cli.json service.json; do
    cp "$ROOT/config/$f" "$dir/config/$f"
  done
  cp "$ROOT/VERSION" "$ROOT/OPENCODE_VERSION" "$ROOT/CHANGELOG.md" \
     "$ROOT/NOTICE" "$ROOT/LICENSE" "$ROOT/LICENSE-OpenCode" \
     "$ROOT/README.txt" "$dir/"
  cp "$ROOT/scripts/fetch-binary.sh" "$ROOT/scripts/lib.sh" "$dir/scripts/"
  cp "$src_bin" "$dir/bin/$bin_name"
  cp "$ROOT/launch.$launcher" "$dir/launch.$launcher"

  find "$dir" -type d -exec chmod 755 {} +
  find "$dir" -type f -exec chmod 644 {} +
  chmod 755 "$dir/launch.$launcher" "$dir/scripts/fetch-binary.sh"
  if [ "$launcher" = "sh" ]; then
    chmod 755 "$dir/bin/$bin_name"
  fi
  if [ "$launcher" = "cmd" ]; then
    # .cmd и .txt должны быть с CRLF независимо от состояния worktree.
    for f in "$dir/launch.cmd" "$dir/README.txt"; do
      awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$f" > "$f.tmp"
      mv "$f.tmp" "$f"
    done
  fi
}

echo "== Assembling Windows bundle =="
make_common "$WIN_DIR" cmd "$WIN_BIN" opencode.exe
if command -v zip >/dev/null 2>&1; then
  ( cd "$WIN_BUILD" && zip -qr -X "$STAGE/opencode-portable-windows-x64.zip" opencode-portable-windows-x64 )
else
  python3 - "$WIN_BUILD" "$STAGE/opencode-portable-windows-x64.zip" <<'PY'
import os, sys, zipfile
src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        for d in dirs:
            arc = os.path.relpath(os.path.join(root, d), src) + "/"
            z.writestr(arc, "")
        for f in files:
            p = os.path.join(root, f)
            z.write(p, os.path.relpath(p, src))
PY
fi

echo "== Assembling Linux bundle =="
make_common "$LINUX_DIR" sh "$LINUX_BIN" opencode
TAR_OWNER=()
if tar --version 2>/dev/null | grep -q 'GNU tar'; then
  TAR_OWNER=(--owner=0 --group=0 --numeric-owner)
fi
tar "${TAR_OWNER[@]}" -C "$LINUX_BUILD" -czf "$STAGE/opencode-portable-linux-x64.tar.gz" opencode-portable-linux-x64

mv "$STAGE/opencode-portable-windows-x64.zip" "$OUT/opencode-portable-windows-x64.zip"
mv "$STAGE/opencode-portable-linux-x64.tar.gz" "$OUT/opencode-portable-linux-x64.tar.gz"
WIN_SHA="$(sha256_file "$OUT/opencode-portable-windows-x64.zip")"
LINUX_SHA="$(sha256_file "$OUT/opencode-portable-linux-x64.tar.gz")"
{
  printf '%s  %s\n' "$WIN_SHA" "opencode-portable-windows-x64.zip"
  printf '%s  %s\n' "$LINUX_SHA" "opencode-portable-linux-x64.tar.gz"
} > "$OUT/SHA256SUMS"
rmdir "$STAGE" 2>/dev/null || true

echo "== Done: $OUT =="
ls -la "$OUT"
