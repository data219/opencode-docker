load ../test_helper

setup() {
  TEST_COMPOSE_PROJECT="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_CONTAINER_NAME="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_PORT="${TEST_OPENCODE_PORT:-4010}"
  TEST_HEALTH_TIMEOUT="${TEST_HEALTH_TIMEOUT:-300}"
  TEST_COMPOSE_FILE="$(mktemp "${PWD}/.test-compose.XXXXXX.yml")"
  TEST_DATA_ROOT="$(mktemp -d "${PWD}/.test-data.XXXXXX")"

  export ZHIPU_API_KEY="test"
  export GEMINI_API_KEY=""
  export OPENCODE_MODE="web"
  export OPENCODE_PORT="4000"
  export OPENCODE_BIND_ADDRESS="127.0.0.1"

  mkdir -p \
    "${TEST_DATA_ROOT}/config" \
    "${TEST_DATA_ROOT}/share" \
    "${TEST_DATA_ROOT}/state" \
    "${TEST_DATA_ROOT}/workspace" \
    "${TEST_DATA_ROOT}/skills"
  chmod 0777 \
    "${TEST_DATA_ROOT}/config" \
    "${TEST_DATA_ROOT}/share" \
    "${TEST_DATA_ROOT}/state" \
    "${TEST_DATA_ROOT}/workspace" \
    "${TEST_DATA_ROOT}/skills"

  cp docker-compose.yml "$TEST_COMPOSE_FILE"
  sed -i "s/container_name: opencode/container_name: ${TEST_CONTAINER_NAME}/" "$TEST_COMPOSE_FILE"
  sed -i "s|\${OPENCODE_BIND_ADDRESS:-127.0.0.1}:\${OPENCODE_PORT:-4000}:\${OPENCODE_PORT:-4000}|127.0.0.1:${TEST_PORT}:4000|" "$TEST_COMPOSE_FILE"
  sed -i "s|\./data/config|${TEST_DATA_ROOT}/config|" "$TEST_COMPOSE_FILE"
  sed -i "s|\./data/share|${TEST_DATA_ROOT}/share|" "$TEST_COMPOSE_FILE"
  sed -i "s|\./data/state|${TEST_DATA_ROOT}/state|" "$TEST_COMPOSE_FILE"
  sed -i "s|\./data/workspace|${TEST_DATA_ROOT}/workspace|" "$TEST_COMPOSE_FILE"
  sed -i "s|\./data/skills|${TEST_DATA_ROOT}/skills|" "$TEST_COMPOSE_FILE"
}

teardown() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    -f "$TEST_COMPOSE_FILE" \
    down -v --remove-orphans >/dev/null 2>&1 || true
  rm -f "$TEST_COMPOSE_FILE"
  rm -rf "$TEST_DATA_ROOT"
}

compose_ci() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    -f "$TEST_COMPOSE_FILE" \
    "$@"
}

wait_for_http_health() {
  local url="$1"
  local timeout="${2:-120}"
  local interval=2
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  return 1
}

@test "compose stack boots and exposes opencode health" {
  run compose_ci up -d
  [ "$status" -eq 0 ]

  if ! wait_for_http_health "http://127.0.0.1:${TEST_PORT}/health" "$TEST_HEALTH_TIMEOUT"; then
    compose_ci ps >&3 || true
    compose_ci logs --tail=200 opencode >&3 || true
    false
  fi

  run curl -fsS "http://127.0.0.1:${TEST_PORT}/health"
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode test -f /home/opencode/.config/opencode/oh-my-openagent.jsonc
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode test -f /opt/opencode-defaults/oh-my-openagent-omo.json
  [ "$status" -eq 0 ]
}
