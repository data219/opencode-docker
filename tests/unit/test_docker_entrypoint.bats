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

  # Mock openchamber binary
  echo '#!/bin/bash' > "$MOCK_BIN_DIR/openchamber"
  echo 'echo "mock-openchamber: $@"' >> "$MOCK_BIN_DIR/openchamber"
  echo 'echo "mock-openchamber-allow-unauthenticated-lan: ${OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN:-}"' >> "$MOCK_BIN_DIR/openchamber"
  chmod +x "$MOCK_BIN_DIR/openchamber"
  
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
    -u OPENCHAMBER_ENABLED
    -u OPENCHAMBER_PORT
    -u OPENCHAMBER_UI_PASSWORD
    -u OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN
    -u OPENCHAMBER_DATA_DIR
    -u USER_HOME
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

@test "entrypoint grants opencode access to mounted Docker socket before dropping privileges" {
  socket_path="$(mktemp)"
  log_file="$(mktemp)"

  cat > "$MOCK_BIN_DIR/id" <<'MOCK'
#!/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo "0"
  exit 0
fi
exec /usr/bin/id "$@"
MOCK
  cat > "$MOCK_BIN_DIR/getent" <<'MOCK'
#!/bin/bash
exit 2
MOCK
  cat > "$MOCK_BIN_DIR/groupadd" <<'MOCK'
#!/bin/bash
echo "groupadd $*" >> "$MOCK_DOCKER_SOCKET_LOG"
MOCK
  cat > "$MOCK_BIN_DIR/usermod" <<'MOCK'
#!/bin/bash
echo "usermod $*" >> "$MOCK_DOCKER_SOCKET_LOG"
MOCK
  cat > "$MOCK_BIN_DIR/gosu" <<'MOCK'
#!/bin/bash
echo "gosu $1" >> "$MOCK_DOCKER_SOCKET_LOG"
shift
exec "$@"
MOCK
  chmod +x "$MOCK_BIN_DIR/id" "$MOCK_BIN_DIR/getent" "$MOCK_BIN_DIR/groupadd" "$MOCK_BIN_DIR/usermod" "$MOCK_BIN_DIR/gosu"

  run_entrypoint \
    MOCK_DOCKER_SOCKET_LOG="$log_file" \
    OPENCODE_DOCKER_SOCKET="$socket_path" \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000

  rm -f "$socket_path"
  [ "$status" -eq 0 ]
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000"
  grep -q "groupadd -g" "$log_file"
  grep -q "usermod -aG" "$log_file"
  grep -q "gosu opencode" "$log_file"
  rm -f "$log_file"
}

@test "entrypoint rejects invalid log level" {
  run_entrypoint OPENCODE_MODE=web OPENCODE_PORT=4000 OPENCODE_LOG_LEVEL=TRACE
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_LOG_LEVEL"
}

@test "entrypoint removes stale OpenChamber pid file before starting" {
  openchamber_data_dir="$(mktemp -d)"
  mkdir -p "$openchamber_data_dir/run"
  echo "$$" > "$openchamber_data_dir/run/openchamber-4020.pid"
  echo '{"port":4020}' > "$openchamber_data_dir/run/openchamber-4020.json"

  run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020 \
    OPENCHAMBER_DATA_DIR="$openchamber_data_dir"

  [ "$status" -eq 0 ]
  assert_output --partial "Removing stale OpenChamber runtime files for port 4020"
  assert_output --partial "mock-openchamber: serve --port 4020 --host 0.0.0.0 --foreground"
  [ ! -e "$openchamber_data_dir/run/openchamber-4020.pid" ]
  [ ! -e "$openchamber_data_dir/run/openchamber-4020.json" ]

  rm -rf "$openchamber_data_dir"
}

@test "entrypoint removes OpenChamber pid file when process command line is unreadable" {
  openchamber_data_dir="$(mktemp -d)"
  mkdir -p "$openchamber_data_dir/run"
  echo "$$" > "$openchamber_data_dir/run/openchamber-4020.pid"
  echo '{"port":4020}' > "$openchamber_data_dir/run/openchamber-4020.json"

  cat > "$MOCK_BIN_DIR/tr" <<'MOCK'
#!/bin/bash
exit 0
MOCK
  chmod +x "$MOCK_BIN_DIR/tr"

  run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020 \
    OPENCHAMBER_DATA_DIR="$openchamber_data_dir"

  [ "$status" -eq 0 ]
  assert_output --partial "Removing stale OpenChamber runtime files for port 4020"
  [ ! -e "$openchamber_data_dir/run/openchamber-4020.pid" ]
  [ ! -e "$openchamber_data_dir/run/openchamber-4020.json" ]

  rm -rf "$openchamber_data_dir"
}

@test "entrypoint continues when stale OpenChamber runtime files cannot be removed" {
  openchamber_data_dir="$(mktemp -d)"
  fail_bin_dir="$(mktemp -d)"
  original_path="$PATH"
  mkdir -p "$openchamber_data_dir/run"
  echo "$$" > "$openchamber_data_dir/run/openchamber-4020.pid"
  echo '{"port":4020}' > "$openchamber_data_dir/run/openchamber-4020.json"

  cat > "$fail_bin_dir/rm" <<'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$fail_bin_dir/rm"

  PATH="$fail_bin_dir:$PATH" run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020 \
    OPENCHAMBER_DATA_DIR="$openchamber_data_dir"
  PATH="$original_path"

  [ "$status" -eq 0 ]
  assert_output --partial "WARNING: Failed to remove stale OpenChamber runtime files; continuing startup"
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000"

  rm -rf "$openchamber_data_dir" "$fail_bin_dir"
}

@test "entrypoint starts OpenChamber without USER_HOME or data dir override" {
  run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020

  [ "$status" -eq 0 ]
  assert_output --partial "mock-openchamber: serve --port 4020 --host 0.0.0.0 --foreground"
  assert_output --partial "mock-opencode: web --hostname 0.0.0.0 --port 4000"
}

@test "entrypoint forwards OpenChamber unauthenticated LAN flag" {
  run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020 \
    OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN=true

  [ "$status" -eq 0 ]
  assert_output --partial "mock-openchamber-allow-unauthenticated-lan: true"
}

@test "entrypoint keeps OpenChamber pid file for running OpenChamber process" {
  openchamber_data_dir="$(mktemp -d)"
  mkdir -p "$openchamber_data_dir/run"
  bash -c 'exec -a openchamber sleep 30' &
  running_openchamber_pid=$!
  echo "$running_openchamber_pid" > "$openchamber_data_dir/run/openchamber-4020.pid"
  echo '{"port":4020}' > "$openchamber_data_dir/run/openchamber-4020.json"

  run_entrypoint \
    OPENCODE_MODE=web \
    OPENCODE_PORT=4000 \
    OPENCHAMBER_ENABLED=true \
    OPENCHAMBER_PORT=4020 \
    OPENCHAMBER_DATA_DIR="$openchamber_data_dir"

  kill "$running_openchamber_pid" 2>/dev/null || true
  wait "$running_openchamber_pid" 2>/dev/null || true

  [ "$status" -eq 0 ]
  refute_output --partial "Removing stale OpenChamber runtime files"
  [ -e "$openchamber_data_dir/run/openchamber-4020.pid" ]
  [ -e "$openchamber_data_dir/run/openchamber-4020.json" ]

  rm -rf "$openchamber_data_dir"
}
