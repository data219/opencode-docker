# Helper: create opencode user for tests running as root
setup_init_test_env() {
  INIT_TEST_TMPDIR="$(mktemp -d)"
  export INIT_MARKER="$INIT_TEST_TMPDIR/marker"
  export DEFAULTS_DIR="$INIT_TEST_TMPDIR/defaults"
  export CONFIG_DIR="$INIT_TEST_TMPDIR/config"
  mkdir -p "$DEFAULTS_DIR" "$CONFIG_DIR"
  # If running as root, ensure opencode user exists for chown block
  if [ "$(id -u)" = "0" ]; then
    id opencode 2>/dev/null || useradd -u 1000 -M -s /bin/bash opencode 2>/dev/null || true
    mkdir -p /home/opencode/.config /home/opencode/.local /home/opencode/.local/share /home/opencode/.local/state /home/opencode/.local/share/opencode /home/opencode/workspace
  fi
}

teardown_init_test_env() {
  rm -f "$INIT_MARKER"
  rm -rf "$INIT_TEST_TMPDIR"
}

@test "docker-init.sh skips if marker file exists" {
  setup_init_test_env
  touch "$INIT_MARKER"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  teardown_init_test_env
}

@test "docker-init.sh creates marker file after successful init" {
  setup_init_test_env
  echo '{"test": true}' > "$DEFAULTS_DIR/opencode.json"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$INIT_MARKER" ]
  teardown_init_test_env
}

@test "docker-init.sh seeds config when target does not exist" {
  setup_init_test_env
  echo '{"test": true}' > "$DEFAULTS_DIR/opencode.json"
  echo '{"agent": true}' > "$DEFAULTS_DIR/oh-my-openagent.jsonc"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$CONFIG_DIR/opencode.json" ]
  [ -f "$CONFIG_DIR/oh-my-openagent.jsonc" ]
  teardown_init_test_env
}

@test "docker-init.sh skips config when target already exists" {
  setup_init_test_env
  echo '{"test": true}' > "$DEFAULTS_DIR/opencode.json"
  echo '// user modified' > "$CONFIG_DIR/opencode.json"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  # init should NOT overwrite existing user config
  [ "$(cat "$CONFIG_DIR/opencode.json")" = "// user modified" ]
  teardown_init_test_env
}

@test "docker-init.sh seeds hidden files (dotglob)" {
  setup_init_test_env
  echo "1" > "$DEFAULTS_DIR/.opencode-docker-config-version"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$CONFIG_DIR/.opencode-docker-config-version" ]
  teardown_init_test_env
}

@test "docker-init.sh merges bootstrap skills without overwriting user files" {
  setup_init_test_env

  local skills_dir="/home/opencode/.config/opencode/skills"
  rm -rf "$skills_dir"
  mkdir -p "$DEFAULTS_DIR/skills/github" "$skills_dir/github"

  echo "bootstrap-new" > "$DEFAULTS_DIR/skills/github/new.txt"
  echo "bootstrap-existing" > "$DEFAULTS_DIR/skills/github/existing.txt"
  echo "user-customized" > "$skills_dir/github/existing.txt"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$skills_dir/github/existing.txt")" = "user-customized" ]
  [ "$(cat "$skills_dir/github/new.txt")" = "bootstrap-new" ]

  rm -rf "$skills_dir"
  teardown_init_test_env
}

@test "docker-init.sh fixes ownership for bind-mounted state directory" {
  if [ "$(id -u)" != "0" ]; then
    skip "requires root to verify chown behavior"
  fi

  setup_init_test_env

  local state_dir="/home/opencode/.local/state/opencode"
  mkdir -p "$state_dir"
  chown root:root "$state_dir"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ "$(stat -c %U:%G "$state_dir")" = "opencode:opencode" ]

  rm -rf "$state_dir"
  teardown_init_test_env
}

@test "docker-init.sh uses cp -a with double-dash" {
  grep -q 'cp -a --' scripts/docker-init.sh
}

@test "docker-init.sh creates config directory with mkdir -p" {
  setup_init_test_env
  CONFIG_DIR="$INIT_TEST_TMPDIR/subdir/config"
  mkdir -p "$(dirname "$CONFIG_DIR")"
  rm -rf "$CONFIG_DIR"
  run bash -c "INIT_MARKER=$INIT_MARKER CONFIG_DIR=$CONFIG_DIR DEFAULTS_DIR=$DEFAULTS_DIR bash scripts/docker-init.sh 2>/dev/null" || true
  [ -d "$CONFIG_DIR" ]
  teardown_init_test_env
}

@test "docker-init.sh has trap ERR" {
  grep -q 'trap.*ERR' scripts/docker-init.sh
}

@test "docker-init.sh does not fail when DEFAULTS_DIR does not exist" {
  # Script gracefully skips seeding when defaults dir is absent
  export INIT_MARKER="$(mktemp -d)/marker-skip"
  export DEFAULTS_DIR="/nonexistent-path"
  export CONFIG_DIR="$(mktemp -d)/config"
  rm -f "$INIT_MARKER"
  mkdir -p "$CONFIG_DIR"
  run bash scripts/docker-init.sh 2>/dev/null
  [ "$status" -eq 0 ]
  [ -f "$INIT_MARKER" ]
  rm -f "$INIT_MARKER"
  rm -rf "$CONFIG_DIR"
}

@test "docker-init.sh has env-var-overridable INIT_MARKER" {
  grep -q 'INIT_MARKER="${INIT_MARKER:-' scripts/docker-init.sh
}

@test "docker-init.sh has env-var-overridable DEFAULTS_DIR" {
  grep -q 'DEFAULTS_DIR="${DEFAULTS_DIR:-' scripts/docker-init.sh
}

@test "docker-init.sh has env-var-overridable CONFIG_DIR" {
  grep -q 'CONFIG_DIR="${CONFIG_DIR:-' scripts/docker-init.sh
}

@test "docker-init.sh uses dotglob for hidden file seeding" {
  grep -q 'dotglob' scripts/docker-init.sh
}
