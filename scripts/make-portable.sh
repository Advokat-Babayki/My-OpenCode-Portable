#!/usr/bin/env bash
# Собирает переносимые бандлы OpenCode V2 для Windows и Linux из официальных бинарей.
#
# Usage:
#   bash scripts/make-portable.sh [VERSION]
#
# VERSION — тег upstream (например 2.2.6). Если не указан — берётся последний V2.
# Результат: release/opencode-portable-windows-x64.zip, release/opencode-portable-linux-x64.tar.gz
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
  echo "Не удалось определить версию OpenCode V2. Укажи её явно: bash scripts/make-portable.sh 2.2.6" >&2
  exit 1
fi

BASE="https://github.com/$UPSTREAM/releases/download/v$VER"
DL="$(mktemp -d)"
OUT="$ROOT/release"
rm -rf "$OUT"
mkdir -p "$OUT"
trap 'rm -rf "$DL"' EXIT

echo "== opencode-portable $VER =="
echo "== Downloading upstream binaries =="
curl -fL --retry 3 -o "$DL/win.zip" "$BASE/opencode-windows-x64.zip"
curl -fL --retry 3 -o "$DL/linux.tgz" "$BASE/opencode-linux-x64.tar.gz"

mkdir -p "$DL/win/bin" "$DL/linux/bin"
unzip -oq "$DL/win.zip" -d "$DL/win/bin"
tar -xzf "$DL/linux.tgz" -C "$DL/linux/bin"

make_common() {
  local dir="$1" launcher="$2"
  mkdir -p "$dir/config" "$dir/data" "$dir/cache" "$dir/state" "$dir/tmp"
  for sub in agents commands plugins skills; do
    mkdir -p "$dir/config/$sub"
  done
  for f in opencode.json AGENTS.md cli.json service.json; do
    cp "$ROOT/config/$f" "$dir/config/$f"
  done
  cp "$ROOT/launch.$launcher" "$dir/launch.$launcher"
  cp "$ROOT/LICENSE" "$dir/LICENSE"
  cp "$ROOT/README.md" "$dir/README.md"
  cp "$ROOT/README.txt" "$dir/README.txt"
}

echo "== Assembling Windows bundle =="
make_common "$DL/win" cmd
if command -v zip >/dev/null 2>&1; then
  ( cd "$DL/win" && zip -qr "$OUT/opencode-portable-windows-x64.zip" . )
else
  echo "zip not found, using python3 zipfile"
  python3 - "$DL/win" "$OUT/opencode-portable-windows-x64.zip" <<'PY'
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
make_common "$DL/linux" sh
chmod +x "$DL/linux/bin/opencode" "$DL/linux/launch.sh"
( cd "$DL/linux" && tar -czf "$OUT/opencode-portable-linux-x64.tar.gz" . )

echo "== Done: $OUT =="
ls -la "$OUT"
