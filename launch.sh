#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

export OPENCODE_CONFIG="$ROOT/config/opencode.json"
export OPENCODE_CONFIG_DIR="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_CACHE_HOME="$ROOT/cache"
export OPENCODE_DISABLE_AUTOUPDATE=true
export OPENCODE_DISABLE_LSP_DOWNLOAD=true

BIN="$ROOT/bin/opencode"

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
