#!/bin/bash
# docker-entrypoint.sh — Per-start dispatch (placeholder for Step 6)
set -euo pipefail

INIT_SCRIPT="${OPENCODE_DOCKER_INIT_SCRIPT:-/scripts/docker-init.sh}"
"$INIT_SCRIPT"

# Args after mode are silently ignored.
# Use environment variables for all OpenCode configuration.
if [ $# -gt 0 ] && [ -n "${OPENCODE_MODE:-}" ]; then
  echo "NOTE: CLI argument '$1' ignored (OPENCODE_MODE env var takes priority)" >&2
fi
if [ "${OPENCODE_MODE+x}" = "x" ]; then
  MODE="$OPENCODE_MODE"
else
  MODE="${1:-web}"
fi
if [ $# -gt 0 ]; then
  shift
fi
PORT="${OPENCODE_PORT:-4000}"
SERVER_USERNAME_RAW="${OPENCODE_SERVER_USERNAME:-}"
SERVER_PASSWORD_RAW="${OPENCODE_SERVER_PASSWORD:-}"
SERVER_CORS_RAW="${OPENCODE_CORS:-}"
PRINT_LOGS_RAW="${OPENCODE_PRINT_LOGS:-false}"
LOG_LEVEL_RAW="${OPENCODE_LOG_LEVEL:-}"

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

case "$PRINT_LOGS_RAW" in
  true|TRUE|1|yes|YES)
    PRINT_LOGS=true
    ;;
  false|FALSE|0|no|NO|"")
    PRINT_LOGS=false
    ;;
  *)
    echo "ERROR: Invalid OPENCODE_PRINT_LOGS='$PRINT_LOGS_RAW'. Must be one of: true, false" >&2
    exit 1
    ;;
esac

LOG_LEVEL=""
if [ -n "$LOG_LEVEL_RAW" ]; then
  LOG_LEVEL="$(printf '%s' "$LOG_LEVEL_RAW" | tr '[:lower:]' '[:upper:]')"
  case "$LOG_LEVEL" in
    DEBUG|INFO|WARN|ERROR) ;;
    *)
      echo "ERROR: Invalid OPENCODE_LOG_LEVEL='$LOG_LEVEL_RAW'. Must be one of: DEBUG, INFO, WARN, ERROR" >&2
      exit 1
      ;;
  esac
fi

if [ -z "$SERVER_PASSWORD_RAW" ]; then
  echo "NOTE: OPENCODE_SERVER_PASSWORD is not set. Ensure host-level port binding restricts access." >&2
fi

# Empty runtime env vars should not override OpenCode defaults.
if [ -z "$SERVER_USERNAME_RAW" ]; then
  unset OPENCODE_SERVER_USERNAME
fi
if [ -z "$SERVER_PASSWORD_RAW" ]; then
  unset OPENCODE_SERVER_PASSWORD
fi

# Optional Docker host delegation. Mounting the Docker socket grants broad
# control over the host daemon, so this only runs when explicitly configured.
if [ "$(id -u)" = "0" ] && [ -n "${OPENCODE_DOCKER_SOCKET:-}" ] && [ -e "$OPENCODE_DOCKER_SOCKET" ]; then
  SOCKET_GID="$(stat -c '%g' "$OPENCODE_DOCKER_SOCKET")"
  if [ -n "$SOCKET_GID" ]; then
    SOCKET_GROUP="$(getent group "$SOCKET_GID" | cut -d: -f1 || true)"
    if [ -z "$SOCKET_GROUP" ]; then
      SOCKET_GROUP="opencode-docker-${SOCKET_GID}"
      groupadd -g "$SOCKET_GID" "$SOCKET_GROUP"
    fi
    usermod -aG "$SOCKET_GROUP" opencode
  fi
fi

# --- Config drift detection ---
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"
CONFIG_VERSION_FILE="$CONFIG_DIR/.opencode-docker-config-version"
IMAGE_DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
IMAGE_VERSION_FILE="$IMAGE_DEFAULTS_DIR/.opencode-docker-config-version"
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

if [ "$PRINT_LOGS" = "true" ]; then
  CMD+=(--print-logs)
fi

if [ -n "$LOG_LEVEL" ]; then
  CMD+=(--log-level "$LOG_LEVEL")
fi

if [ -n "$SERVER_CORS_RAW" ]; then
  CMD+=(--cors "$SERVER_CORS_RAW")
fi

if [ "$(id -u)" = "0" ]; then
  exec gosu opencode "${CMD[@]}"
else
  exec "${CMD[@]}"
fi
