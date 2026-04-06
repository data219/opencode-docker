#!/bin/bash
# docker-init.sh — One-time initialization (placeholder for Step 6)
set -euo pipefail
trap 'echo "ERROR: docker-init.sh failed at line $LINENO" >&2' ERR

INIT_MARKER="${INIT_MARKER:-/home/opencode/.opencode-docker-initialized}"
DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"

if [ -f "$INIT_MARKER" ]; then
  exit 0
fi

mkdir -p "$CONFIG_DIR"

if [ -d "$DEFAULTS_DIR" ]; then
  shopt -s dotglob nullglob
  for item in "$DEFAULTS_DIR"/*; do
    [ -e "$item" ] || continue
    target="$CONFIG_DIR/$(basename "$item")"
    if [ ! -e "$target" ]; then
      cp -a -- "$item" "$target"
    fi
  done
  shopt -u dotglob nullglob
fi

if [ "$(id -u)" = "0" ]; then
  for dir in .config .local .local/share .local/state .local/share/opencode workspace; do
    dir_path="/home/opencode/$dir"
    if [ -d "$dir_path" ] && [ "$(stat -c %U "$dir_path" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir_path"
    fi
  done
fi

touch "$INIT_MARKER"
