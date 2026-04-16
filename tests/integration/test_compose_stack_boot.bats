load ../test_helper

setup() {
  TEST_COMPOSE_PROJECT="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_CONTAINER_NAME="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_OPENCODE_PORT="${TEST_OPENCODE_PORT:-$((4100 + ($$ % 2000) + BATS_TEST_NUMBER))}"
  TEST_HEALTH_TIMEOUT="${TEST_HEALTH_TIMEOUT:-300}"
  TEST_HOME_ROOT=""
}

prepare_test_stack() {
  TEST_OPENCODE_PORT="${1:-$TEST_OPENCODE_PORT}"
  TEST_HOME_ROOT="$(mktemp -d "${PWD}/.test-home.XXXXXX")"

  export ZHIPU_API_KEY="test"
  export GEMINI_API_KEY=""
  export OPENCODE_MODE="web"
  export OPENCODE_PORT="${TEST_OPENCODE_PORT}"
  export OPENCODE_BIND_ADDRESS="127.0.0.1"
  export OPENCODE_CONTAINER_NAME="${TEST_CONTAINER_NAME}"
  export OPENCODE_HOME_DIR="${TEST_HOME_ROOT}"

  chmod 0777 "${TEST_HOME_ROOT}"
}

teardown() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    down -v --remove-orphans >/dev/null 2>&1 || true
  if [ -d "$TEST_HOME_ROOT" ]; then
    docker run --rm \
      -v "${TEST_HOME_ROOT}:/mnt" \
      alpine sh -lc 'rm -rf /mnt/* /mnt/.[!.]* /mnt/..?* 2>/dev/null || true' \
      >/dev/null 2>&1 || true
  fi
  rm -rf "$TEST_HOME_ROOT"
}

compose_ci() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    "$@"
}

wait_for_http_health() {
  local url="$1"
  local timeout="${2:-120}"
  local interval=2
  local elapsed=0
  local request_timeout="${TEST_HEALTH_REQUEST_TIMEOUT:-2}"

  while [ "$elapsed" -lt "$timeout" ]; do
    if curl --max-time "$request_timeout" -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval + request_timeout))
  done

  return 1
}

@test "compose stack boots and loads OmO runtime config in opencode" {
  prepare_test_stack
  run compose_ci up -d --build
  [ "$status" -eq 0 ]

  if ! wait_for_http_health "http://127.0.0.1:${OPENCODE_PORT}/health" "$TEST_HEALTH_TIMEOUT"; then
    compose_ci ps >&3 || true
    compose_ci logs --tail=200 opencode >&3 || true
    false
  fi

  run curl -fsS "http://127.0.0.1:${OPENCODE_PORT}/health"
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode test -f /home/opencode/.config/opencode/oh-my-openagent.jsonc
  [ "$status" -eq 0 ]
  [ -f "${TEST_HOME_ROOT}/.config/opencode/oh-my-openagent.jsonc" ]

  run compose_ci exec -T -u opencode opencode sh -lc 'opencode debug paths | grep -F "config     /home/opencode/.config/opencode"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    config_dump="$(mktemp)"
    opencode debug config > "$config_dump"
    grep -F "\"plugin\": [" "$config_dump"
    grep -F "\"oh-my-openagent\"" "$config_dump"
    grep -F "\"plugin_origins\"" "$config_dump"
    grep -F "\"spec\": \"oh-my-openagent\"" "$config_dump"
    grep -F "/home/opencode/.config/opencode" "$config_dump"
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v agent-browser'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v gh'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v glab'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v atlcli'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode test -f /opt/opencode-defaults/oh-my-openagent-omo.json
  [ "$status" -eq 0 ]
}
