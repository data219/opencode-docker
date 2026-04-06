#!/bin/bash
# test_helper.bash — Loads bats-support/bats-assert + custom Docker helpers
# R3-M15: bats-support and bats-assert replace custom assertion implementations

# Load bats-support and bats-assert (vendored, version-pinned)
BATS_TEST_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
load "${BATS_TEST_HELPER_DIR}/bats-support/load.bash"
load "${BATS_TEST_HELPER_DIR}/bats-assert/load.bash"

# --- Custom Docker Helpers ---

# assert_valid_json <file> — validates JSON via jq
assert_valid_json() {
  local file="$1"
  jq . "$file" > /dev/null 2>&1
}

# assert_json_key <file> <key> — checks that a jq key exists and is non-null
assert_json_key() {
  local file="$1"
  local key="$2"
  jq -e "$key" "$file" > /dev/null
}

# wait_for_healthy <project> <timeout> — polling loop for docker compose healthcheck
# R3-M16: Replaces all sleep-based waits
# R4-M18: Default 120s for first-start, 30s for restart. Polling interval: sleep 2.
wait_for_healthy() {
  local project="$1"
  local timeout="${2:-120}"
  local interval=2
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    # Use docker compose ps to check health status
    local status
    status=$(docker compose -p "$project" ps --format '{{.Name}} {{.Health}}' 2>/dev/null || true)
    if echo "$status" | grep -q "healthy"; then
      return 0
    fi
    echo "  [wait_for_healthy] $elapsed/${timeout}s — $status" >&2
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "  [wait_for_healthy] TIMEOUT after ${timeout}s" >&2
  return 1
}

# teardown_docker — shared Docker cleanup for integration tests (R3-L8)
teardown_docker() {
  # Override in test files or call docker compose -p <project> down -v
  true
}

# MOCK_BIN_DIR — temp dir for mock scripts in unit tests (R3-L9)
# Default to a temp dir if not set; individual tests override per-setup
MOCK_BIN_DIR="${MOCK_BIN_DIR:-/tmp/mock-bin-$$}"
