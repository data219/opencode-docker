load ../test_helper

setup() {
  TEST_COMPOSE_PROJECT="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_CONTAINER_NAME="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_OPENCODE_PORT="${TEST_OPENCODE_PORT:-$((4100 + ($$ % 2000) + BATS_TEST_NUMBER))}"
  TEST_HEALTH_TIMEOUT="${TEST_HEALTH_TIMEOUT:-300}"
  TEST_STACK_START_ATTEMPTS="${TEST_STACK_START_ATTEMPTS:-2}"
  TEST_HOME_ROOT=""
}

prepare_test_stack() {
  TEST_OPENCODE_PORT="${1:-$TEST_OPENCODE_PORT}"
  TEST_HOME_ROOT="$(mktemp -d "${PWD}/.test-home.XXXXXX")"

  export OCD_ZHIPU_API_KEY="test"
  export OCD_GEMINI_API_KEY=""
  export GIT_AUTHOR_NAME=""
  export GIT_AUTHOR_EMAIL=""
  export GIT_COMMITTER_NAME=""
  export GIT_COMMITTER_EMAIL=""
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
  local request_timeout="${TEST_HEALTH_REQUEST_TIMEOUT:-2}"
  local next_progress=30
  local start_time
  local elapsed

  start_time="$(date +%s)"

  while true; do
    elapsed=$(($(date +%s) - start_time))
    if [ "$elapsed" -ge "$timeout" ]; then
      return 1
    fi

    if curl --max-time "$request_timeout" -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if [ "$elapsed" -ge "$next_progress" ]; then
      echo "  [wait_for_http_health] ${elapsed}/${timeout}s waiting for $url" >&3
      next_progress=$((next_progress + 30))
    fi
    sleep "$interval"
  done
}

print_stack_diagnostics() {
  compose_ci ps >&3 || true
  compose_ci logs --tail=200 opencode >&3 || true
  docker inspect \
    --format 'health={{json .State.Health}}' \
    "$TEST_CONTAINER_NAME" >&3 2>&1 || true
  compose_ci exec -T opencode sh -lc '
    echo "container-health-probe:"
    curl -sv --max-time 5 "http://127.0.0.1:${OPENCODE_PORT}/health"
  ' >&3 2>&1 || true
}

start_test_stack() {
  run compose_ci up -d --build
  [ "$status" -eq 0 ]

  local attempt=1
  while [ "$attempt" -le "$TEST_STACK_START_ATTEMPTS" ]; do
    if wait_for_http_health "http://127.0.0.1:${OPENCODE_PORT}/health" "$TEST_HEALTH_TIMEOUT"; then
      return 0
    fi

    print_stack_diagnostics
    if [ "$attempt" -lt "$TEST_STACK_START_ATTEMPTS" ]; then
      echo "  [start_test_stack] health check timed out; restarting stack attempt $((attempt + 1))/${TEST_STACK_START_ATTEMPTS}" >&3
      compose_ci restart opencode >&3 || true
    fi
    attempt=$((attempt + 1))
  done

  false
}

@test "compose stack boots and serves health endpoint" {
  prepare_test_stack
  start_test_stack

  run curl -fsS "http://127.0.0.1:${OPENCODE_PORT}/health"
  [ "$status" -eq 0 ]
}

@test "compose stack loads OmO runtime config in opencode" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode test -f /home/opencode/.config/opencode/oh-my-openagent.jsonc
  [ "$status" -eq 0 ]
  [ -f "${TEST_HOME_ROOT}/.config/opencode/oh-my-openagent.jsonc" ]

  run compose_ci exec -T -u opencode opencode sh -lc 'opencode debug paths | grep -F "config     /home/opencode/.config/opencode"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v jq >/dev/null 2>&1 || {
      echo "ERROR: jq is required for OmO runtime config assertions but is not installed in the container." >&2
      exit 1
    }
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    config_dump="$(mktemp)"
    opencode debug config > "$config_dump"
    jq -e "
      .plugin | index(\"oh-my-openagent\")
    " "$config_dump" >/dev/null
    jq -e "
      any(
        .plugin_origins[];
        .spec == \"oh-my-openagent\"
        and .scope == \"global\"
      )
    " "$config_dump" >/dev/null
  '
  [ "$status" -eq 0 ]
}

@test "compose stack provides bundled CLIs and defaults" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode sh -lc 'command -v agent-browser'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v gh'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v glab'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v atlcli'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v python >/dev/null &&
    command -v python3 >/dev/null &&
    python --version >/dev/null &&
    python3 --version >/dev/null &&
    python -m pip --version >/dev/null &&
    python -m venv /tmp/opencode-python-smoke &&
    /tmp/opencode-python-smoke/bin/python -c "print(\"python-ready\")"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "python-ready" ]

  run compose_ci exec -T opencode test -f /opt/opencode-defaults/oh-my-openagent-omo.json
  [ "$status" -eq 0 ]
}

@test "compose stack renders PDFs via agent-browser" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T -u opencode opencode sh -lc '
    agent-browser open "http://127.0.0.1:${OPENCODE_PORT}/health" >/tmp/agent-browser-open.log 2>&1 &&
    agent-browser pdf /tmp/example.pdf >/tmp/agent-browser-pdf.log 2>&1 &&
    test -s /tmp/example.pdf
  '
  [ "$status" -eq 0 ]
}

@test "compose stack forwards cors flag and strips empty auth username env" {
  prepare_test_stack
  export OPENCODE_CORS="https://example.com"
  export OPENCODE_SERVER_USERNAME=""

  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    tr "\0" " " < /proc/1/cmdline | grep -F -- "--cors https://example.com"
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^OPENCODE_SERVER_USERNAME="; then
      echo "OPENCODE_SERVER_USERNAME leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]
}

@test "compose stack applies default git identity config without exporting reserved git env vars" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_NAME="; then
      echo "GIT_AUTHOR_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_EMAIL="; then
      echo "GIT_AUTHOR_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_NAME="; then
      echo "GIT_COMMITTER_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_EMAIL="; then
      echo "GIT_COMMITTER_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test -s /home/opencode/.gitmessage'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get user.name)" = "Oh-MyOpenAgent"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get user.email)" = "noreply@ohmyopencode.ai"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get author.name >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get author.email >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get committer.name >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get committer.email >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get commit.template)" = "/home/opencode/.gitmessage"'
  [ "$status" -eq 0 ]
}

@test "compose stack applies explicit git identity overrides without exporting reserved git env vars" {
  prepare_test_stack
  export GIT_AUTHOR_NAME="Override Author"
  export GIT_AUTHOR_EMAIL="override-author@example.test"
  export GIT_COMMITTER_NAME="Override Committer"
  export GIT_COMMITTER_EMAIL="override-committer@example.test"
  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_NAME="; then
      echo "GIT_AUTHOR_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_EMAIL="; then
      echo "GIT_AUTHOR_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_NAME="; then
      echo "GIT_COMMITTER_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_EMAIL="; then
      echo "GIT_COMMITTER_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get author.name)" = "Override Author"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get author.email)" = "override-author@example.test"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get committer.name)" = "Override Committer"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get committer.email)" = "override-committer@example.test"'
  [ "$status" -eq 0 ]
}
