#!/bin/bash
# docker-init.sh — One-time initialization
set -euo pipefail
trap 'echo "ERROR: docker-init.sh failed at line $LINENO" >&2' ERR

INIT_MARKER="${INIT_MARKER:-/home/opencode/.opencode-docker-initialized}"
DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"

if [ -f "$INIT_MARKER" ]; then
  exit 0
fi

# Fix ownership of bind-mounted directories BEFORE seeding.
# Docker creates bind mount targets as root when they don't exist on host.
if [ "$(id -u)" = "0" ]; then
  for dir in .config .config/opencode .local .local/share .local/state .local/share/opencode workspace; do
    dir_path="/home/opencode/$dir"
    if [ -d "$dir_path" ] && [ "$(stat -c %U "$dir_path" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir_path"
    fi
  done
fi

mkdir -p "$CONFIG_DIR"

# Seed default configs (only if not already present — Image already has them,
# this covers empty bind-mount volumes on first container start).
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

# Seed OmO agent config if not yet present (OmO install writes to temp dir during build).
if [ ! -f "$CONFIG_DIR/oh-my-openagent.jsonc" ] && [ -f "$DEFAULTS_DIR/oh-my-openagent-omo.json" ]; then
  cp -a -- "$DEFAULTS_DIR/oh-my-openagent-omo.json" "$CONFIG_DIR/oh-my-openagent.jsonc"
fi

touch "$INIT_MARKER"
