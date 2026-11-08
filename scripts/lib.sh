#!/usr/bin/env bash
# Общие функции для скриптов обслуживания. Не запускается напрямую.

UPSTREAM="${UPSTREAM:-anomalyco/opencode}"

is_version() {
  [[ "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

latest_v2() {
  curl -fsSL --proto '=https' --proto-redir '=https' \
    "https://api.github.com/repos/$UPSTREAM/releases?per_page=50" \
    | grep -oE '"tag_name": *"v2\.[0-9]+\.[0-9]+"' \
    | sed -E 's/.*"v(2\.[^"]*)"/\1/' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -n1
}

sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  else
    echo "Нет sha256sum, shasum или openssl для подсчёта SHA-256" >&2
    return 1
  fi
}

verify_sha256() {
  local file="$1" name="$2" sums="$3" expected actual
  if [ ! -f "$sums" ]; then
    echo "Нет файла SHA256SUMS для проверки $name" >&2
    return 1
  fi
  expected="$(awk -v n="$name" '$2==n {print $1; exit}' "$sums")"
  if [ -z "$expected" ]; then
    echo "SHA256 для $name не найден в SHA256SUMS" >&2
    return 1
  fi
  actual="$(sha256_file "$file")" || return 1
  if [ "$actual" != "$expected" ]; then
    echo "SHA256 не совпал для $name" >&2
    return 1
  fi
  echo "sha256 ok: $name"
}
