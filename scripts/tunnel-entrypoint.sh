#!/bin/bash
# tunnel-entrypoint.sh — Starts cloudflared in quick or managed mode.
#
# Quick mode (default, no Cloudflare account needed):
#   Generates a random *.trycloudflare.com URL on every start.
#   Set CF_TUNNEL_MODE=quick (or leave unset).
#
# Managed mode (requires Cloudflare account + tunnel token):
#   Uses a pre-configured named tunnel with a stable domain.
#   Set CF_TUNNEL_MODE=managed and CF_TUNNEL_TOKEN=<your-token>.
#
# The target service is resolved via Docker DNS (opencode:4000).
set -euo pipefail

MODE="${CF_TUNNEL_MODE:-quick}"
TARGET_HOST="${CF_TUNNEL_TARGET_HOST:-opencode}"
TARGET_PORT="${CF_TUNNEL_TARGET_PORT:-4000}"
TARGET_URL="http://${TARGET_HOST}:${TARGET_PORT}"

case "$MODE" in
  quick)
    echo "Starting Cloudflare Quick Tunnel (no account required)..."
    echo "  Target: ${TARGET_URL}"
    echo "  A random *.trycloudflare.com URL will be assigned."
    echo "  Check container logs for the URL:"
    echo "    docker compose logs -f cloudflared"
    echo ""
    exec cloudflared tunnel --url "$TARGET_URL" 2>&1
    ;;
  managed)
    if [ -z "${CF_TUNNEL_TOKEN:-}" ]; then
      echo "ERROR: CF_TUNNEL_MODE=managed but CF_TUNNEL_TOKEN is not set." >&2
      echo "  Create a tunnel at https://one.dash.cloudflare.com/ and set CF_TUNNEL_TOKEN." >&2
      exit 1
    fi
    echo "Starting Cloudflare Managed Tunnel..."
    echo "  Target: ${TARGET_URL} (configured in Cloudflare dashboard)"
    echo "  Token: ${CF_TUNNEL_TOKEN:0:8}..."
    echo ""
    exec cloudflared tunnel --no-autoupdate run --token "$CF_TUNNEL_TOKEN" 2>&1
    ;;
  *)
    echo "ERROR: Invalid CF_TUNNEL_MODE='${MODE}'. Must be 'quick' or 'managed'." >&2
    exit 1
    ;;
esac
