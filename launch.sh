#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

export OPENCODE_CONFIG_DIR="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_CACHE_HOME="$ROOT/cache"
export XDG_STATE_HOME="$ROOT/state"
export TMPDIR="$ROOT/tmp"
export OPENCODE_DISABLE_AUTOUPDATE=true

mkdir -p "$ROOT/data" "$ROOT/cache" "$ROOT/state" "$ROOT/tmp"

BIN="$ROOT/bin/opencode"

if [ ! -f "$BIN" ]; then
  echo "opencode: bin/opencode не найден." >&2
  echo "Скачай бинарь: bash scripts/fetch-binary.sh" >&2
  exit 1
fi

if [ -x "$BIN" ]; then
  exec "$BIN" "$@"
fi

# На exFAT exec-бит может не сохраняться — запускаем через динамический загрузчик.
loader=""
for c in /lib64/ld-linux-x86-64.so.2 \
         /usr/lib64/ld-linux-x86-64.so.2 \
         /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
         /usr/lib/ld-linux-x86-64.so.2; do
  if [ -x "$c" ]; then loader="$c"; break; fi
done

if [ -z "$loader" ] && command -v readelf >/dev/null 2>&1; then
  loader="$(readelf -l "$BIN" 2>/dev/null | awk '/interpreter:/{print $NF; exit}')"
fi

if [ -n "$loader" ] && [ -x "$loader" ]; then
  exec "$loader" "$BIN" "$@"
fi

echo "opencode: нельзя выполнить bin/opencode (нет exec-бита и не найден динамический загрузчик)." >&2
echo "Перемонтируй флешку с опцией exec, например:" >&2
echo "  sudo mount -o remount,exec $ROOT" >&2
exit 1
