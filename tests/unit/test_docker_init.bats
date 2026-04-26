# Helper: create opencode user for tests running as root
setup_init_test_env() {
  INIT_TEST_TMPDIR="$(mktemp -d)"
  export DEFAULTS_DIR="$INIT_TEST_TMPDIR/defaults"
  export CONFIG_DIR="$INIT_TEST_TMPDIR/config"
  export USER_HOME="$INIT_TEST_TMPDIR/home"
  export HOME="$USER_HOME"
  export GIT_CONFIG_GLOBAL="$USER_HOME/.gitconfig"
  mkdir -p "$DEFAULTS_DIR" "$CONFIG_DIR"
  mkdir -p "$USER_HOME"
  # If running as root, ensure opencode user exists for chown block
  if [ "$(id -u)" = "0" ]; then
    id opencode 2>/dev/null || useradd -u 1000 -M -s /bin/bash opencode 2>/dev/null || true
    mkdir -p /home/opencode/.config /home/opencode/.local /home/opencode/.local/share /home/opencode/.local/state /home/opencode/.local/share/opencode /home/opencode/workspace
  fi
}

teardown_init_test_env() {
  unset DEFAULTS_DIR CONFIG_DIR USER_HOME HOME GIT_CONFIG_GLOBAL
  rm -rf "$INIT_TEST_TMPDIR"
}

@test "docker-init.sh seeds ~/.gitmessage only once" {
  setup_init_test_env

  export USER_HOME="$INIT_TEST_TMPDIR/home"
  mkdir -p "$USER_HOME"
  echo "Co-Authored-By: Oh-My-OpenAgent (OpenCode) <agent@ohmyopencode.ai>" > "$DEFAULTS_DIR/.gitmessage"

  rm -f "$USER_HOME/.gitmessage"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$USER_HOME/.gitmessage" ]
  grep -F "Co-Authored-By: Oh-My-OpenAgent (OpenCode) <agent@ohmyopencode.ai>" "$USER_HOME/.gitmessage"

  echo "user-customized-template" > "$USER_HOME/.gitmessage"
  touch -t 202001010000 "$USER_HOME/.gitmessage"
  before_mtime="$(stat -c %Y "$USER_HOME/.gitmessage")"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ "$(stat -c %Y "$USER_HOME/.gitmessage")" -eq "$before_mtime" ]
  grep -F "user-customized-template" "$USER_HOME/.gitmessage"

  rm -f "$USER_HOME/.gitmessage"
  unset USER_HOME
  teardown_init_test_env
}

@test "docker-init.sh configures global git author and committer from env vars" {
  setup_init_test_env

  export HOME="$(mktemp -d)"
  export USER_HOME="$HOME"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  export GIT_AUTHOR_NAME="Custom Author"
  export GIT_AUTHOR_EMAIL="custom-author@example.com"
  export GIT_COMMITTER_NAME="Custom Committer"
  export GIT_COMMITTER_EMAIL="custom-committer@example.com"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]

  run git config --global --get author.name
  [ "$status" -eq 0 ]
  [ "$output" = "Custom Author" ]

  run git config --global --get author.email
  [ "$status" -eq 0 ]
  [ "$output" = "custom-author@example.com" ]

  run git config --global --get committer.name
  [ "$status" -eq 0 ]
  [ "$output" = "Custom Committer" ]

  run git config --global --get committer.email
  [ "$status" -eq 0 ]
  [ "$output" = "custom-committer@example.com" ]

  run git config --global --get user.name
  [ "$status" -eq 0 ]
  [ "$output" = "Custom Author" ]

  run git config --global --get user.email
  [ "$status" -eq 0 ]
  [ "$output" = "custom-author@example.com" ]

  run git config --global --get commit.template
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.gitmessage" ]

  rm -rf "$HOME"
  unset HOME USER_HOME GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  teardown_init_test_env
}

@test "docker-init.sh falls back to default git identity values" {
  setup_init_test_env

  export HOME="$(mktemp -d)"
  export USER_HOME="$HOME"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]

  run git config --global --get author.name
  [ "$status" -eq 0 ]
  [ "$output" = "Oh-MyOpenAgent" ]

  run git config --global --get author.email
  [ "$status" -eq 0 ]
  [ "$output" = "noreply@ohmyopencode.ai" ]

  run git config --global --get committer.name
  [ "$status" -eq 0 ]
  [ "$output" = "Oh-MyOpenAgent" ]

  run git config --global --get committer.email
  [ "$status" -eq 0 ]
  [ "$output" = "noreply@ohmyopencode.ai" ]

  run git config --global --get commit.template
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.gitmessage" ]

  rm -rf "$HOME"
  unset HOME USER_HOME GIT_CONFIG_GLOBAL
  teardown_init_test_env
}

@test "docker-init.sh preserves existing config on version upgrade and updates version marker" {
  setup_init_test_env

  echo '{"old": true}' > "$CONFIG_DIR/opencode.json"
  echo '{"new": true}' > "$DEFAULTS_DIR/opencode.json"
  echo "1" > "$CONFIG_DIR/.opencode-docker-config-version"
  echo "2" > "$DEFAULTS_DIR/.opencode-docker-config-version"
  touch -t 202001010000 "$CONFIG_DIR/opencode.json" "$CONFIG_DIR/.opencode-docker-config-version"
  touch -t 202001020000 "$DEFAULTS_DIR/.opencode-docker-config-version"
  before_config_mtime="$(stat -c %Y "$CONFIG_DIR/opencode.json")"
  before_version_mtime="$(stat -c %Y "$CONFIG_DIR/.opencode-docker-config-version")"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$CONFIG_DIR/opencode.json" ]
  [ -f "$CONFIG_DIR/.opencode-docker-config-version" ]
  [ "$(stat -c %Y "$CONFIG_DIR/opencode.json")" -eq "$before_config_mtime" ]
  [ "$(stat -c %Y "$CONFIG_DIR/.opencode-docker-config-version")" -gt "$before_version_mtime" ]
  teardown_init_test_env
}

@test "docker-init.sh copies version marker after successful init" {
  setup_init_test_env
  echo '{"test": true}' > "$DEFAULTS_DIR/opencode.json"
  echo "3" > "$DEFAULTS_DIR/.opencode-docker-config-version"
  touch -t 202001030000 "$DEFAULTS_DIR/.opencode-docker-config-version"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$CONFIG_DIR/.opencode-docker-config-version" ]
  [ "$(stat -c %Y "$CONFIG_DIR/.opencode-docker-config-version")" -gt 0 ]
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
  touch -t 202001010000 "$CONFIG_DIR/opencode.json"
  before_mtime="$(stat -c %Y "$CONFIG_DIR/opencode.json")"
  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$CONFIG_DIR/opencode.json" ]
  [ "$(stat -c %Y "$CONFIG_DIR/opencode.json")" -eq "$before_mtime" ]
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
  mkdir -p "$DEFAULTS_DIR/skills/github"
  if ! mkdir -p "$skills_dir/github" 2>/dev/null; then
    skip "requires writable /home/opencode skill directory"
  fi

  echo "bootstrap-new" > "$DEFAULTS_DIR/skills/github/new.txt"
  echo "bootstrap-existing" > "$DEFAULTS_DIR/skills/github/existing.txt"
  echo "user-customized" > "$skills_dir/github/existing.txt"
  touch -t 202001010000 "$skills_dir/github/existing.txt"
  before_existing_mtime="$(stat -c %Y "$skills_dir/github/existing.txt")"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ -f "$skills_dir/github/new.txt" ]
  [ "$(stat -c %Y "$skills_dir/github/existing.txt")" -eq "$before_existing_mtime" ]

  rm -rf "$skills_dir"
  teardown_init_test_env
}

@test "docker-init.sh preserves bind-mount ownership for synced skills" {
  if [ "$(id -u)" != "0" ]; then
    skip "requires root to verify ownership normalization"
  fi

  setup_init_test_env

  local skills_dir="/home/opencode/.config/opencode/skills"
  local expected_owner="12345:12346"
  rm -rf "$skills_dir"
  mkdir -p "$DEFAULTS_DIR/skills/github" "$skills_dir"
  chown "$expected_owner" "$skills_dir"
  echo "bootstrap-new" > "$DEFAULTS_DIR/skills/github/new.txt"

  run bash scripts/docker-init.sh
  [ "$status" -eq 0 ]
  [ "$(stat -c '%u:%g' "$skills_dir")" = "$expected_owner" ]
  [ "$(stat -c '%u:%g' "$skills_dir/github")" = "$expected_owner" ]
  [ "$(stat -c '%u:%g' "$skills_dir/github/new.txt")" = "$expected_owner" ]

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

@test "docker-init.sh creates config directory with mkdir -p" {
  setup_init_test_env
  CONFIG_DIR="$INIT_TEST_TMPDIR/subdir/config"
  mkdir -p "$(dirname "$CONFIG_DIR")"
  rm -rf "$CONFIG_DIR"
  run bash -c "CONFIG_DIR=$CONFIG_DIR DEFAULTS_DIR=$DEFAULTS_DIR bash scripts/docker-init.sh 2>/dev/null" || true
  [ -d "$CONFIG_DIR" ]
  teardown_init_test_env
}

@test "docker-init.sh does not fail when DEFAULTS_DIR does not exist" {
  # Script gracefully skips seeding when defaults dir is absent
  export DEFAULTS_DIR="/nonexistent-path"
  export CONFIG_DIR="$(mktemp -d)/config"
  export USER_HOME="$(mktemp -d)"
  export HOME="$USER_HOME"
  export GIT_CONFIG_GLOBAL="$USER_HOME/.gitconfig"
  mkdir -p "$CONFIG_DIR"
  run bash scripts/docker-init.sh 2>/dev/null
  [ "$status" -eq 0 ]
  [ -d "$CONFIG_DIR" ]
  [ ! -f "$CONFIG_DIR/.opencode-docker-config-version" ]
  rm -rf "$CONFIG_DIR" "$USER_HOME"
  unset DEFAULTS_DIR CONFIG_DIR USER_HOME HOME GIT_CONFIG_GLOBAL
}
