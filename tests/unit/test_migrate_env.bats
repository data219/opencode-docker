load ../test_helper

setup() {
  TEST_TMPDIR="$(mktemp -d "${PWD}/.test-env-migrate.XXXXXX")"
  TEST_ENV_FILE="${TEST_TMPDIR}/.env"
  TEST_EXAMPLE_FILE="${TEST_TMPDIR}/.env.example"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

assert_env_file_contains() {
  local file="$1"
  local pattern="$2"

  grep -Eq "$pattern" "$file"
}

refute_env_file_contains() {
  local file="$1"
  local pattern="$2"

  ! grep -Eq "$pattern" "$file"
}

@test "migrate-env renames legacy api key variables preserving values" {
  cat > "$TEST_ENV_FILE" <<'EOF'
ZHIPU_API_KEY=zai-secret
GEMINI_API_KEY=gemini-secret
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
OCD_GEMINI_API_KEY=
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_ZHIPU_API_KEY=zai-secret$'
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_GEMINI_API_KEY=gemini-secret$'
  refute_env_file_contains "$TEST_ENV_FILE" '^ZHIPU_API_KEY='
  refute_env_file_contains "$TEST_ENV_FILE" '^GEMINI_API_KEY='
}

@test "migrate-env adds missing example entries with matching comment status" {
  cat > "$TEST_ENV_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=already-set
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
OCD_GEMINI_API_KEY=
# OPENCODE_MODE=web
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_ZHIPU_API_KEY=already-set$'
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_GEMINI_API_KEY=$'
  assert_env_file_contains "$TEST_ENV_FILE" '^# OPENCODE_MODE=web$'
}

@test "migrate-env does not overwrite existing renamed variable" {
  cat > "$TEST_ENV_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=current-secret
ZHIPU_API_KEY=legacy-secret
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_ZHIPU_API_KEY=current-secret$'
  assert_env_file_contains "$TEST_ENV_FILE" '^# ZHIPU_API_KEY=legacy-secret$'
}

@test "migrate-env ignores commented renamed placeholders when migrating active legacy values" {
  cat > "$TEST_ENV_FILE" <<'EOF'
# OCD_ZHIPU_API_KEY=
ZHIPU_API_KEY=legacy-secret
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_ZHIPU_API_KEY=legacy-secret$'
  assert_env_file_contains "$TEST_ENV_FILE" '^# OCD_ZHIPU_API_KEY=$'
  refute_env_file_contains "$TEST_ENV_FILE" '^ZHIPU_API_KEY=legacy-secret$'
}

@test "migrate-env fills empty renamed variable from populated legacy variable" {
  cat > "$TEST_ENV_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
ZHIPU_API_KEY=legacy-secret
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OCD_ZHIPU_API_KEY=legacy-secret$'
  assert_env_file_contains "$TEST_ENV_FILE" '^# ZHIPU_API_KEY=legacy-secret$'
}
