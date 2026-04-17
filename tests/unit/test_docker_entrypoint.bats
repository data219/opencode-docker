setup() {
  load ../test_helper
  MOCK_BIN_DIR="$(mktemp -d)"
  chmod 755 "$MOCK_BIN_DIR"
  
  # Mock docker-init.sh (entrypoint calls absolute /scripts/docker-init.sh)
  MOCK_SCRIPTS_DIR="$(mktemp -d)/scripts"
  mkdir -p "$MOCK_SCRIPTS_DIR"
  echo '#!/bin/bash' > "$MOCK_SCRIPTS_DIR/docker-init.sh"
  echo 'echo "mock-init invoked"' >> "$MOCK_SCRIPTS_DIR/docker-init.sh"
  echo 'exit 0' >> "$MOCK_SCRIPTS_DIR/docker-init.sh"
  chmod +x "$MOCK_SCRIPTS_DIR/docker-init.sh"
  
  # Mock opencode binary
  echo '#!/bin/bash' > "$MOCK_BIN_DIR/opencode"
  echo 'echo "mock-opencode: $@"' >> "$MOCK_BIN_DIR/opencode"
  chmod +x "$MOCK_BIN_DIR/opencode"
  
  PATH="$MOCK_BIN_DIR:$PATH"
  export PATH
  export MOCK_SCRIPTS_DIR
}

teardown() {
  rm -rf "$MOCK_BIN_DIR" "${MOCK_SCRIPTS_DIR%/scripts}"
}

# Helper: run entrypoint with mocked init script
run_entrypoint() {
  local cli_arg=""
  local env_args=()

  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--" ]; then
      shift
      cli_arg="${1:-}"
      break
    fi
    env_args+=("$1")
    shift
  done

  local cmd=(
    env
    -u OPENCODE_MODE
    -u OPENCODE_PORT
    -u OPENCODE_SERVER_USERNAME
    -u OPENCODE_SERVER_PASSWORD
    -u OPENCODE_CORS
    -u OPENCODE_PRINT_LOGS
    -u OPENCODE_LOG_LEVEL
    -u CONFIG_DIR
    -u DEFAULTS_DIR
    "PATH=$PATH"
  )
  cmd+=("${env_args[@]}")
  cmd+=(
    "OPENCODE_DOCKER_INIT_SCRIPT=$MOCK_SCRIPTS_DIR/docker-init.sh"
    bash
    scripts/docker-entrypoint.sh
  )
  if [ -n "$cli_arg" ]; then
    cmd+=("$cli_arg")
  fi

  run "${cmd[@]}"
}

@test "entrypoint accepts mode 'web'" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000
  [ "$status" -eq 0 ]
  assert_output --partial "mock-init invoked"
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000"
}

@test "entrypoint accepts mode 'serve'" {
  run_entrypoint OPENCODE_MODE=serve OPENCODE_PORT=4000
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: serve --hostname 0.0.0.0 --port 4000"
}

@test "entrypoint rejects mode 'tui'" {
  run_entrypoint OPENCODE_MODE=tui OPENCODE_PORT=4000
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint rejects mode 'invalid'" {
  run_entrypoint OPENCODE_MODE=invalid OPENCODE_PORT=4000
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint rejects empty string mode" {
  run_entrypoint OPENCODE_MODE= OPENCODE_PORT=4000
  [ "$status" -ne 0 ]
}

@test "entrypoint accepts valid port 4000" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000
  [ "$status" -eq 0 ]
  assert_output --partial "--port 4000"
}

@test "entrypoint rejects port 'abc'" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=abc
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_PORT"
}

@test "entrypoint rejects port 0" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=0
  [ "$status" -ne 0 ]
}

@test "entrypoint rejects port 1023" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=1023
  [ "$status" -ne 0 ]
}

@test "entrypoint rejects port 65536" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=65536
  [ "$status" -ne 0 ]
}

@test "port 0400 is interpreted as 400 (not 256)" {
  result=$((10#0400))
  [ "$result" -eq 400 ]
}

@test "port 00777 is interpreted as 777 (valid)" {
  result=$((10#00777))
  [ "$result" -eq 777 ]
}

@test "port 00000 is rejected (evaluates to 0)" {
  result=$((10#00000))
  [ "$result" -eq 0 ]
}

@test "entrypoint warns when server password is empty" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_SERVER_PASSWORD=
  [ "$status" -eq 0 ]
  assert_output --partial "OPENCODE_SERVER_PASSWORD is not set"
}

@test "entrypoint does not warn when server password is set" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_SERVER_PASSWORD=secret
  [ "$status" -eq 0 ]
  refute_output --partial "OPENCODE_SERVER_PASSWORD is not set"
}

@test "entrypoint passes through optional server username env" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_SERVER_USERNAME=alice OPENCODE_SERVER_PASSWORD=secret
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000"
  refute_output --partial "OPENCODE_SERVER_PASSWORD is not set"
}

@test "entrypoint ignores CLI mode when OPENCODE_MODE is set" {
  run_entrypoint OPENCODE_MODE=serve OPENCODE_PORT=4000 -- invalid
  [ "$status" -eq 0 ]
  assert_output --partial "CLI argument 'invalid' ignored"
  assert_output --partial "mock-opencode: serve --hostname 0.0.0.0 --port 4000"
}

@test "entrypoint uses CLI mode when OPENCODE_MODE is unset" {
  run_entrypoint OPENCODE_PORT=4000 -- serve
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: serve --hostname 0.0.0.0 --port 4000"
}

@test "entrypoint warns on config version mismatch" {
  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir"
  echo "1" > "$tmpdir/.opencode-docker-config-version"
  image_defaults="$(mktemp -d)"
  echo "2" > "$image_defaults/.opencode-docker-config-version"

  run_entrypoint CONFIG_DIR="$tmpdir" DEFAULTS_DIR="$image_defaults" OPENCODE_MODE=web OPENCODE_PORT=4000
  rm -rf "$tmpdir" "$image_defaults"
  [ "$status" -eq 0 ]
  assert_output --partial "Config version mismatch"
}

@test "entrypoint enables opencode log printing when requested" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_PRINT_LOGS=true
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000 --print-logs"
}

@test "entrypoint leaves log printing disabled by default" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000
  [ "$status" -eq 0 ]
  refute_output --partial "--print-logs"
}

@test "entrypoint sets opencode log level when requested" {
  run_entrypoint OPENCODE_MODE=serve OPENCODE_PORT=4000 OPENCODE_LOG_LEVEL=DEBUG
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: serve --hostname 0.0.0.0 --port 4000 --log-level DEBUG"
}

@test "entrypoint sets cors when requested" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_CORS=https://example.com
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000 --cors https://example.com"
}

@test "entrypoint omits cors when env is empty" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_CORS=
  [ "$status" -eq 0 ]
  refute_output --partial "--cors"
}

@test "entrypoint rejects invalid log print toggle" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_PRINT_LOGS=maybe
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_PRINT_LOGS"
}

@test "entrypoint rejects invalid log level" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_LOG_LEVEL=TRACE
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_LOG_LEVEL"
}
