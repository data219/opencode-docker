load ../test_helper

setup() {
  TEST_HOME_DIR="$(mktemp -d "${PWD}/.test-config-switch-home.XXXXXX")"
  TEST_CWD_DIR="$(mktemp -d "${PWD}/.test-config-switch-cwd.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_HOME_DIR"
  rm -rf "$TEST_CWD_DIR"
}

config_dir() {
  printf '%s/.config/opencode' "$TEST_HOME_DIR"
}

@test "config-switch requires a variant" {
  run scripts/config-switch.sh

  assert_failure
  assert_output --partial "Usage: scripts/config-switch.sh <variant>"
}

@test "config-switch rejects unknown variants" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh missing-variant

  assert_failure
  assert_output --partial "ERROR: unknown config variant: missing-variant"
  assert_output --partial "Available variants:"
}

@test "config-switch rejects path traversal variant names" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh ..

  assert_failure
  assert_output --partial "ERROR: unknown config variant: .."
  assert_output --partial "Available variants:"
}

@test "config-switch rejects nested traversal variant names" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt/../../config

  assert_failure
  assert_output --partial "ERROR: unknown config variant: openai-chatgpt/../../config"
  assert_output --partial "Available variants:"
}

@test "config-switch rejects absolute variant names" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh /absolute

  assert_failure
  assert_output --partial "ERROR: unknown config variant: /absolute"
  assert_output --partial "Available variants:"
}

@test "config-switch writes openai-chatgpt runtime config to OPENCODE_HOME_DIR" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  assert_output --partial "Switched OpenCode config variant to openai-chatgpt"
  assert_output --partial "task opencode -- auth login --provider openai --method"

  [ -f "$(config_dir)/opencode.json" ]
  [ -f "$(config_dir)/oh-my-openagent.jsonc" ]
  [ -f "$(config_dir)/AGENTS.md" ]
  [ -f "$(config_dir)/.opencode-docker-config-version" ]

  cmp -s bootstrap/config/variants/openai-chatgpt/opencode.json "$(config_dir)/opencode.json"
  cmp -s bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc "$(config_dir)/oh-my-openagent.jsonc"
}

@test "config-switch resolves repository paths from script location" {
  run bash -c 'cd "$1" && OPENCODE_HOME_DIR="$2" "$3" openai-chatgpt' _ "$TEST_CWD_DIR" "$TEST_HOME_DIR" "$PWD/scripts/config-switch.sh"

  assert_success
  cmp -s bootstrap/config/variants/openai-chatgpt/opencode.json "$(config_dir)/opencode.json"
  cmp -s bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc "$(config_dir)/oh-my-openagent.jsonc"
}

@test "config-switch writes zai-coding-plan runtime config to OPENCODE_HOME_DIR" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh zai-coding-plan

  assert_success
  assert_output --partial "Switched OpenCode config variant to zai-coding-plan"
  assert_output --partial "Ensure OCD_ZHIPU_API_KEY is set"

  cmp -s bootstrap/config/variants/zai-coding-plan/opencode.json "$(config_dir)/opencode.json"
  cmp -s bootstrap/config/variants/zai-coding-plan/oh-my-openagent.jsonc "$(config_dir)/oh-my-openagent.jsonc"
}

@test "config-switch preserves existing runtime AGENTS.md" {
  mkdir -p "$(config_dir)"
  printf '%s\n' '# user custom agents' > "$(config_dir)/AGENTS.md"

  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  assert_equal "$(cat "$(config_dir)/AGENTS.md")" "# user custom agents"
}

@test "config-switch overwrites only managed runtime config files" {
  mkdir -p "$(config_dir)"
  printf '%s\n' 'keep me' > "$(config_dir)/custom.txt"
  printf '%s\n' '{"old":true}' > "$(config_dir)/opencode.json"

  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  [ -f "$(config_dir)/custom.txt" ]
  assert_equal "$(cat "$(config_dir)/custom.txt")" "keep me"
  cmp -s bootstrap/config/variants/openai-chatgpt/opencode.json "$(config_dir)/opencode.json"
}
