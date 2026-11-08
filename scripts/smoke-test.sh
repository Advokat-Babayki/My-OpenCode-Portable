#!/usr/bin/env bash
# Статические проверки и проверки лаунчера.
#
# Usage:
#   bash scripts/smoke-test.sh            # + проверка реального bin/opencode, если он есть
#   bash scripts/smoke-test.sh --static   # только статические проверки
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
MODE="${1:-}"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }

for f in "$ROOT/launch.sh" "$ROOT"/scripts/*.sh; do
  bash -n "$f" || fail "синтаксис $f"
done
ok "bash syntax"

for f in launch.sh launch.cmd README.md README.txt VERSION OPENCODE_VERSION \
         CHANGELOG.md NOTICE LICENSE LICENSE-OpenCode \
         config/opencode.json config/AGENTS.md config/cli.json config/service.json \
         scripts/lib.sh scripts/fetch-binary.sh scripts/make-portable.sh; do
  [ -s "$ROOT/$f" ] || fail "нет файла $f"
done
ok "required files"

PROJECT_VER="$(cat "$ROOT/VERSION")"
OC_VER="$(cat "$ROOT/OPENCODE_VERSION")"
is_version "$PROJECT_VER" || fail "VERSION не semver: $PROJECT_VER"
is_version "$OC_VER" || fail "OPENCODE_VERSION не semver: $OC_VER"
if is_version "2.3.0-rc1"; then fail "is_version принимает prerelease"; fi
ok "versions"

command -v python3 >/dev/null 2>&1 || fail "нужен python3"
python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
cfg = json.loads((root / "config/opencode.json").read_text())
assert cfg["model"].startswith("opencode-go/"), cfg["model"]
assert cfg.get("update") == "disable", cfg.get("update")
assert cfg.get("formatter") is False, cfg.get("formatter")
assert cfg.get("lsp") is False, cfg.get("lsp")
assert cfg["experimental"]["todo"] is True, cfg["experimental"]
assert cfg["agents"]["title"]["model"].startswith("opencode/"), cfg["agents"]

cli = json.loads((root / "config/cli.json").read_text())
assert cli["$schema"].endswith("/v2/cli.json"), cli["$schema"]
svc = json.loads((root / "config/service.json").read_text())
assert svc["disabled"] is True, svc

agents = (root / "config/AGENTS.md").read_text()
assert len(agents) > 1000, len(agents)
assert "TODO DISCIPLINE" in agents
assert "MIT License" in (root / "LICENSE-OpenCode").read_text()
assert (root / "NOTICE").stat().st_size > 0
PY
ok "config json"

if grep -RInE '"apiKey"|"api_key"|sk-[A-Za-z0-9]{10,}' "$ROOT/config" >/dev/null 2>&1; then
  fail "похоже на ключ в config/"
fi
ok "no config secrets"

if grep -q 'git clone' "$ROOT/README.txt"; then fail "README.txt содержит git clone"; fi
grep -q 'launch.cmd' "$ROOT/README.txt" || fail "README.txt не упоминает launch.cmd"
grep -q 'launch.sh' "$ROOT/README.txt" || fail "README.txt не упоминает launch.sh"
ok "archive README"

T="$(mktemp -d "${TMPDIR:-/tmp}/opencode-smoke.XXXXXX")"
trap 'rm -rf -- "$T"' EXIT
mkdir -p "$T/bin" "$T/config"
cp "$ROOT/launch.sh" "$T/"
cp -a "$ROOT/config/." "$T/config/"

cat > "$T/bin/opencode" <<'FAKE'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "opencode v2.2.6"
  exit 0
fi
printf 'ARG=%s\n' "$@"
printf 'DATA=%s\n' "$XDG_DATA_HOME"
printf 'STATE=%s\n' "$XDG_STATE_HOME"
printf 'TMP=%s\n' "$TMPDIR"
printf 'OC_CONFIG=%s\n' "${OPENCODE_CONFIG:-}"
printf 'OC_DB=%s\n' "${OPENCODE_DB:-}"
printf 'CLAUDE_SKILLS=%s\n' "${OPENCODE_DISABLE_CLAUDE_CODE_SKILLS:-}"
FAKE
chmod +x "$T/bin/opencode"

out="$(OPENCODE_CONFIG=/tmp/host.json OPENCODE_DB=/tmp/leak.db "$T/launch.sh" run "hello world" 'a&b')"
case "$out" in
  *"ARG=run"*"ARG=hello world"*"ARG=a&b"*) ;;
  *) fail "аргументы потерялись: $out" ;;
esac
case "$out" in *"DATA=$T/data"*) ;; *) fail "XDG_DATA_HOME вне root: $out" ;; esac
case "$out" in *"STATE=$T/state"*) ;; *) fail "XDG_STATE_HOME вне root: $out" ;; esac
case "$out" in *"TMP=$T/tmp"*) ;; *) fail "TMPDIR вне root: $out" ;; esac
printf '%s\n' "$out" | grep -qx 'OC_CONFIG=' || fail "OPENCODE_CONFIG не очищен"
printf '%s\n' "$out" | grep -qx 'OC_DB=' || fail "OPENCODE_DB не очищен"
printf '%s\n' "$out" | grep -qx 'CLAUDE_SKILLS=true' || fail "Claude skills не отключены"
ok "launcher args/paths/isolation"

if stat -c %a "$T/data" >/dev/null 2>&1; then
  mode="$(stat -c %a "$T/data")"
  [ "$mode" = "700" ] || fail "umask: $T/data имеет режим $mode"
  ok "umask 077"
fi

cat > "$T/bin/opencode" <<'FAKE'
#!/usr/bin/env bash
echo "opencode v1.18.16"
FAKE
chmod +x "$T/bin/opencode"
if "$T/launch.sh" --version >/dev/null 2>&1; then
  fail "launcher принял V1-бинарь"
fi
ok "V1 rejected"

rm -f "$T/bin/opencode"
if "$T/launch.sh" --version >/dev/null 2>&1; then
  fail "launcher работает без bin/opencode"
fi
ok "missing binary rejected"

if [ "$MODE" = "--static" ]; then
  echo "static checks passed"
  exit 0
fi

if [ -f "$ROOT/bin/opencode" ]; then
  ver="$("$ROOT/launch.sh" --version)"
  case "$ver" in
    *" v2."*) ;;
    *) fail "bin/opencode не V2: $ver" ;;
  esac
  paths="$("$ROOT/launch.sh" debug paths)"
  for key in data cache state tmp db; do
    line="$(printf '%s\n' "$paths" | awk -v k="$key" '$1==k {print $2}')"
    case "$line" in
      "$ROOT"/*) ;;
      *) fail "$key вне root: ${line:-пусто}" ;;
    esac
  done
  ok "real binary paths"
else
  echo "skip: bin/opencode не найден"
fi

echo "all checks passed"
