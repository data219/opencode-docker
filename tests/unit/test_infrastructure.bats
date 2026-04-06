# Step 0b: Tests for custom helpers in test_helper.bash
# R3-L11: First test just loads test_helper + true (no circular dependency)
@test "test_helper loads without error" {
  load ../test_helper
  true
}

# R4-M19: Unit tests use mktemp -d for /tmp/ isolation, consistent with MOCK_BIN_DIR pattern
setup() {
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "assert_valid_json detects valid JSON" {
  load ../test_helper
  echo '{"key": "value"}' > "$TEST_TMPDIR/test-valid.json"
  assert_valid_json "$TEST_TMPDIR/test-valid.json"
}

@test "assert_valid_json rejects invalid JSON" {
  load ../test_helper
  echo '{not json}' > "$TEST_TMPDIR/test-invalid.json"
  run assert_valid_json "$TEST_TMPDIR/test-invalid.json"
  [ "$status" -ne 0 ]
}

@test "assert_json_key finds existing key" {
  load ../test_helper
  echo '{"provider": {"zai-coding-plan": {}}}' > "$TEST_TMPDIR/test-key.json"
  assert_json_key "$TEST_TMPDIR/test-key.json" '.provider["zai-coding-plan"]'
}

@test "assert_json_key fails on missing key" {
  load ../test_helper
  echo '{"provider": {}}' > "$TEST_TMPDIR/test-nokey.json"
  run assert_json_key "$TEST_TMPDIR/test-nokey.json" '.provider["nonexistent"]'
  [ "$status" -ne 0 ]
}

@test "wait_for_healthy returns 0 when service is healthy" {
  load ../test_helper
  # R4-M17: Actual RED-phase test using MOCK_BIN_DIR
  MOCK_BIN_DIR="$(mktemp -d)"
  echo '#!/bin/bash' > "$MOCK_BIN_DIR/docker"
  echo 'echo "test-service  healthy"' >> "$MOCK_BIN_DIR/docker"
  chmod +x "$MOCK_BIN_DIR/docker"
  PATH="$MOCK_BIN_DIR:$PATH" run wait_for_healthy test-service 5
  [ "$status" -eq 0 ]
  rm -rf "$MOCK_BIN_DIR"
}

@test "wait_for_healthy returns 1 on timeout" {
  load ../test_helper
  # R4-M17: Actual RED-phase test using MOCK_BIN_DIR
  MOCK_BIN_DIR="$(mktemp -d)"
  echo '#!/bin/bash' > "$MOCK_BIN_DIR/docker"
  # Mock docker compose ps that never reports healthy
  echo 'echo "test-service  starting"' >> "$MOCK_BIN_DIR/docker"
  chmod +x "$MOCK_BIN_DIR/docker"
  PATH="$MOCK_BIN_DIR:$PATH" run wait_for_healthy test-service 2
  [ "$status" -eq 1 ]
  rm -rf "$MOCK_BIN_DIR"
}

# R5-L20: Verify teardown_docker and MOCK_BIN_DIR are defined
@test "teardown_docker is defined" {
  load ../test_helper
  type teardown_docker
}

@test "MOCK_BIN_DIR is defined" {
  load ../test_helper
  [ -n "${MOCK_BIN_DIR:-}" ]
}
