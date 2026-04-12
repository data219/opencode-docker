#!/bin/bash
# docker-entrypoint.sh — Per-start dispatch (placeholder for Step 6)
set -euo pipefail

/scripts/docker-init.sh

# Args after mode are silently ignored.
# Use environment variables for all OpenCode configuration.
if [ $# -gt 0 ] && [ -n "${OPENCODE_MODE:-}" ]; then
  echo "NOTE: CLI argument '$1' ignored (OPENCODE_MODE env var takes priority)" >&2
fi
MODE="${OPENCODE_MODE:-${1:-web}}"
if [ $# -gt 0 ]; then
  shift
fi
PORT="${OPENCODE_PORT:-4000}"

case "$MODE" in
  web|serve) ;;
  *)
    echo "ERROR: Invalid OPENCODE_MODE='$MODE'. Must be one of: web, serve" >&2
    echo "  (For CLI/TUI access, use: docker exec -it <container> -- opencode)" >&2
    exit 1
    ;;
esac

if ! echo "$PORT" | grep -qE '^[0-9]{1,5}$' || [ "$((10#$PORT))" -lt 1024 ] || [ "$((10#$PORT))" -gt 65535 ]; then
  echo "ERROR: Invalid OPENCODE_PORT='$PORT'. Must be a number between 1024 and 65535" >&2
  exit 1
fi

if [ -z "${OPENCODE_SERVER_PASSWORD:-}" ]; then
  echo "NOTE: OPENCODE_SERVER_PASSWORD is not set. Ensure host-level port binding restricts access." >&2
fi

# --- Config drift detection ---
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"
CONFIG_VERSION_FILE="$CONFIG_DIR/.opencode-docker-config-version"
IMAGE_VERSION_FILE="/opt/opencode-defaults/.opencode-docker-config-version"
if [ -f "$CONFIG_VERSION_FILE" ] && [ -f "$IMAGE_VERSION_FILE" ]; then
  USER_VERSION=$(head -1 "$CONFIG_VERSION_FILE" 2>/dev/null || echo "unknown")
  IMAGE_VERSION=$(head -1 "$IMAGE_VERSION_FILE" 2>/dev/null || echo "unknown")
  if [ "$USER_VERSION" != "$IMAGE_VERSION" ]; then
    echo "WARNING: Config version mismatch. Image defaults are v$IMAGE_VERSION but your config is v$USER_VERSION." >&2
    echo "  Your config is NOT overwritten. To update manually:" >&2
    echo "    docker exec -it <container> -- cat /opt/opencode-defaults/opencode.json > /home/opencode/.config/opencode/opencode.json" >&2
    echo "  Then update the version marker to match." >&2
  fi
fi

case "$MODE" in
  web)
    CMD=(opencode web --hostname 0.0.0.0 --port "$PORT")
    ;;
  serve)
    CMD=(opencode serve --hostname 0.0.0.0 --port "$PORT")
    ;;
esac

if [ "$(id -u)" = "0" ]; then
  exec gosu opencode "${CMD[@]}"
else
  exec "${CMD[@]}"
fi
