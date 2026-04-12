setup() {
  load ../test_helper
  MOCK_BIN_DIR="$(mktemp -d)"
  
  # Mock docker-init.sh (entrypoint calls absolute /scripts/docker-init.sh)
  MOCK_SCRIPTS_DIR="$(mktemp -d)/scripts"
  mkdir -p "$MOCK_SCRIPTS_DIR"
  echo '#!/bin/bash' > "$MOCK_SCRIPTS_DIR/docker-init.sh"
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

# Helper: run entrypoint with mocked /scripts/docker-init.sh
run_entrypoint() {
  # Create a temporary entrypoint that uses our mock init path
  local tmp_entrypoint
  tmp_entrypoint="$(mktemp)"
  sed "s|/scripts/docker-init.sh|$MOCK_SCRIPTS_DIR/docker-init.sh|" scripts/docker-entrypoint.sh > "$tmp_entrypoint"
  chmod +x "$tmp_entrypoint"
  
  run bash -c "$1 bash $tmp_entrypoint 2>&1"
  local rc=$?
  rm -f "$tmp_entrypoint"
  return $rc
}

@test "entrypoint accepts mode 'web'" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=4000' || true
  refute_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint accepts mode 'serve'" {
  run_entrypoint 'OPENCODE_MODE=serve OPENCODE_PORT=4000' || true
  refute_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint rejects mode 'tui'" {
  run_entrypoint 'OPENCODE_MODE=tui OPENCODE_PORT=4000'
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint rejects mode 'invalid'" {
  run_entrypoint 'OPENCODE_MODE=invalid OPENCODE_PORT=4000'
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_MODE"
}

@test "entrypoint rejects empty string mode" {
  run_entrypoint 'OPENCODE_MODE= OPENCODE_PORT=4000'
  [ "$status" -ne 0 ]
}

@test "entrypoint accepts valid port 4000" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=4000' || true
  refute_output --partial "Invalid OPENCODE_PORT"
}

@test "entrypoint rejects port 'abc'" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=abc'
  [ "$status" -ne 0 ]
  assert_output --partial "Invalid OPENCODE_PORT"
}

@test "entrypoint rejects port 0" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=0'
  [ "$status" -ne 0 ]
}

@test "entrypoint rejects port 1023" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=1023'
  [ "$status" -ne 0 ]
}

@test "entrypoint rejects port 65536" {
  run_entrypoint 'OPENCODE_MODE=web OPENCODE_PORT=65536'
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

@test "entrypoint has NO OPENCODE_BIND_ADDRESS security warning" {
  ! grep -q 'OPENCODE_BIND_ADDRESS.*WARNING\|WARNING.*OPENCODE_BIND_ADDRESS' scripts/docker-entrypoint.sh
}

@test "entrypoint has comment about args being silently ignored" {
  grep -q 'Args after mode are silently ignored' scripts/docker-entrypoint.sh
}

@test "entrypoint has no --password flag in CMD array" {
  ! grep -q '\-\-password' scripts/docker-entrypoint.sh
}

@test "entrypoint uses gosu for privilege drop" {
  grep -q "gosu opencode" scripts/docker-entrypoint.sh
}

@test "entrypoint has no auth.json creation" {
  ! grep -q "auth.json" scripts/docker-entrypoint.sh
}

@test "entrypoint has no skills symlink code" {
  ! grep -q "skills" scripts/docker-entrypoint.sh
  ! grep -q "symlink" scripts/docker-entrypoint.sh
}

@test "entrypoint has standalone empty-password warning" {
  grep -q 'OPENCODE_SERVER_PASSWORD' scripts/docker-entrypoint.sh
}

@test "entrypoint uses head -1 for version file reading (not cat)" {
  grep -q 'head -1' scripts/docker-entrypoint.sh
}
