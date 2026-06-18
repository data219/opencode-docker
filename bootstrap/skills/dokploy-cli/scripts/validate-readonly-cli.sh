#!/usr/bin/env bash
set -euo pipefail

offline_ok=0

for arg in "$@"; do
  case "$arg" in
    --offline-ok)
      offline_ok=1
      ;;
    *)
      printf 'FAIL: unsupported option: %s\n' "$arg" >&2
      exit 1
      ;;
  esac
done

if ! command -v dokploy >/dev/null 2>&1; then
  if [ "$offline_ok" -eq 1 ]; then
    printf 'SKIP: dokploy CLI not found; --offline-ok enabled\n'
    exit 0
  fi
  printf 'FAIL: dokploy CLI not found\n' >&2
  exit 1
fi

tmp_output="$(mktemp)"
trap 'rm -f "$tmp_output"' EXIT

run_safe() {
  label="$1"
  shift
  printf 'run: %s\n' "$label"
  "$@" >"$tmp_output" 2>&1
  printf 'ok: %s\n' "$label"
  : >"$tmp_output"
}

run_safe 'dokploy --help' dokploy --help
run_safe 'dokploy --version' dokploy --version
run_safe 'dokploy project --help' dokploy project --help
run_safe 'dokploy application --help' dokploy application --help

printf 'read-only CLI validation passed\n'
