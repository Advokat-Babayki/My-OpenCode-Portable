#!/usr/bin/env bash
set -euo pipefail

umask 077

SELF="$(readlink -f "$0" 2>/dev/null || printf '%s\n' "$0")"
ROOT="$(cd "$(dirname "$SELF")" && pwd)"

# Не тащить конфиг, базу, ключи и флаги из родительского OpenCode.
for v in ${!OPENCODE_@}; do unset "$v"; done
unset OPENCODE

export OPENCODE_CONFIG_DIR="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_CACHE_HOME="$ROOT/cache"
export XDG_STATE_HOME="$ROOT/state"
export TMPDIR="$ROOT/tmp"
export OPENCODE_DISABLE_AUTOUPDATE=true
export OPENCODE_DISABLE_CLAUDE_CODE=true
export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true

mkdir -p "$ROOT/data" "$ROOT/cache" "$ROOT/state" "$ROOT/tmp"

BIN="$ROOT/bin/opencode"

if [ ! -f "$BIN" ]; then
  echo "opencode: bin/opencode не найден." >&2
  echo "Скачай бинарь: bash \"$ROOT/scripts/fetch-binary.sh\"" >&2
  exit 1
fi

mount_hint() {
  local mnt="$ROOT"
  if command -v findmnt >/dev/null 2>&1; then
    mnt="$(findmnt -n -o TARGET --target "$BIN" 2>/dev/null || true)"
    [ -n "$mnt" ] || mnt="$ROOT"
  fi
  echo "Перемонтируй раздел с опцией exec:" >&2
  printf '  sudo mount -o remount,exec %q\n' "$mnt" >&2
}

if command -v findmnt >/dev/null 2>&1; then
  if findmnt -no OPTIONS --target "$BIN" 2>/dev/null | grep -q 'noexec'; then
    echo "opencode: диск с bin/opencode смонтирован с noexec." >&2
    mount_hint
    exit 1
  fi
fi

CMD=()
if [ -x "$BIN" ]; then
  CMD=("$BIN")
else
  # На exFAT exec-бит может не сохраняться — запускаем через динамический загрузчик.
  loader=""
  for c in /lib64/ld-linux-x86-64.so.2 \
           /usr/lib64/ld-linux-x86-64.so.2 \
           /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
           /usr/lib/ld-linux-x86-64.so.2 \
           /lib/ld-musl-x86_64.so.1 \
           /lib64/ld-linux-aarch64.so.1 \
           /lib/ld-linux-aarch64.so.1 \
           /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
           /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
           /lib/ld-musl-aarch64.so.1; do
    if [ -x "$c" ]; then loader="$c"; break; fi
  done

  if [ -z "$loader" ] && command -v readelf >/dev/null 2>&1; then
    loader="$(LC_ALL=C readelf -l "$BIN" 2>/dev/null \
      | sed -n 's/.*interpreter: *\([^]]*\)].*/\1/p' \
      | head -n1 || true)"
  fi

  if [ -n "$loader" ] && [ -x "$loader" ]; then
    CMD=("$loader" "$BIN")
  else
    echo "opencode: нельзя выполнить bin/opencode (нет exec-бита и не найден динамический загрузчик)." >&2
    echo "Можно запустить лаунчер через bash: bash \"$ROOT/launch.sh\"" >&2
    mount_hint
    exit 1
  fi
fi

ver="$("${CMD[@]}" --version 2>/dev/null || true)"
case "$ver" in
  *" v2."*) ;;
  *)
    echo "opencode: bin/opencode должен быть OpenCode V2, а сообщает: ${ver:-не запускается}." >&2
    echo "Обнови бинарь: bash \"$ROOT/scripts/fetch-binary.sh\"" >&2
    exit 1
    ;;
esac

exec "${CMD[@]}" "$@"
