#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_CONFIG_DIR="$REPO_ROOT/bootstrap/config"
VARIANTS_ROOT="$BOOTSTRAP_CONFIG_DIR/variants"

usage() {
  echo "Usage: scripts/config-switch.sh <variant>" >&2
  echo "Available variants:" >&2
  list_variants >&2
}

list_variants() {
  local variant_dir
  if [ ! -d "$VARIANTS_ROOT" ]; then
    return 0
  fi
  for variant_dir in "$VARIANTS_ROOT"/*; do
    [ -d "$variant_dir" ] || continue
    printf '  %s\n' "$(basename "$variant_dir")"
  done
}

variant_exists() {
  local requested_variant="$1"
  local variant_dir
  if [ ! -d "$VARIANTS_ROOT" ]; then
    return 1
  fi
  for variant_dir in "$VARIANTS_ROOT"/*; do
    [ -d "$variant_dir" ] || continue
    if [ "$requested_variant" = "$(basename "$variant_dir")" ]; then
      return 0
    fi
  done
  return 1
}

copy_required_file() {
  local source="$1"
  local target="$2"
  if [ ! -f "$source" ]; then
    echo "ERROR: required variant file missing: $source" >&2
    exit 1
  fi
  cp -a -- "$source" "$target"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

VARIANT="$1"

if ! variant_exists "$VARIANT"; then
  echo "ERROR: unknown config variant: $VARIANT" >&2
  echo "Available variants:" >&2
  list_variants >&2
  exit 1
fi

VARIANT_DIR="$VARIANTS_ROOT/$VARIANT"

OPENCODE_HOME_DIR="${OPENCODE_HOME_DIR:-./data/home}"
CONFIG_DIR="$OPENCODE_HOME_DIR/.config/opencode"

mkdir -p "$CONFIG_DIR"

copy_required_file "$VARIANT_DIR/opencode.json" "$CONFIG_DIR/opencode.json"
copy_required_file "$VARIANT_DIR/oh-my-openagent.jsonc" "$CONFIG_DIR/oh-my-openagent.jsonc"

if [ ! -f "$CONFIG_DIR/AGENTS.md" ] && [ -f "$BOOTSTRAP_CONFIG_DIR/AGENTS.md" ]; then
  cp -a -- "$BOOTSTRAP_CONFIG_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

if [ -f "$BOOTSTRAP_CONFIG_DIR/.opencode-docker-config-version" ]; then
  cp -a -- "$BOOTSTRAP_CONFIG_DIR/.opencode-docker-config-version" "$CONFIG_DIR/.opencode-docker-config-version"
fi

echo "Switched OpenCode config variant to $VARIANT"
echo "Runtime config: $CONFIG_DIR"

case "$VARIANT" in
  openai-chatgpt)
    echo "Next auth step, if this home has not logged in yet:"
    echo '  task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"'
    ;;
  zai-coding-plan)
    echo "Ensure OCD_ZHIPU_API_KEY is set before starting the stack."
    ;;
esac
