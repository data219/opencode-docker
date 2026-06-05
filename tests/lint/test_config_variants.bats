load ../test_helper

variant_file() {
  local variant="$1"
  local file="$2"
  printf 'bootstrap/config/variants/%s/%s' "$variant" "$file"
}

assert_file_exists() {
  local file="$1"
  [ -f "$file" ] || {
    echo "expected file to exist: $file" >&2
    return 1
  }
}

assert_json_valid() {
  local file="$1"
  jq empty "$file"
}

assert_jsonc_valid() {
  local file="$1"
  node tests/jsonc/validate-jsonc.js "$file"
}

assert_file_matches() {
  local pattern="$1"
  local file="$2"
  grep -Eq "$pattern" "$file"
}

assert_file_not_matches() {
  local pattern="$1"
  local file="$2"
  local status

  grep -Eq "$pattern" "$file"
  status="$?"

  case "$status" in
    0)
      echo "unexpected match for pattern '$pattern' in $file" >&2
      return 1
      ;;
    1)
      return 0
      ;;
    *)
      echo "grep failed while searching $file for pattern '$pattern' (exit $status)" >&2
      return "$status"
      ;;
  esac
}

@test "config variants contain required files" {
  for variant in zai-coding-plan openai-chatgpt; do
    assert_file_exists "$(variant_file "$variant" opencode.json)"
    assert_file_exists "$(variant_file "$variant" oh-my-openagent.jsonc)"
  done
}

@test "variant OpenCode JSON files are valid JSON" {
  for variant in zai-coding-plan openai-chatgpt; do
    run assert_json_valid "$(variant_file "$variant" opencode.json)"
    assert_success
  done
}

@test "variant Oh My OpenAgent JSONC files are parseable" {
  command -v node >/dev/null 2>&1 || skip "node is required for JSONC validation"
  for variant in zai-coding-plan openai-chatgpt; do
    run assert_jsonc_valid "$(variant_file "$variant" oh-my-openagent.jsonc)"
    assert_success
  done
}

@test "JSONC validator reports file read errors with filename" {
  command -v node >/dev/null 2>&1 || skip "node is required for JSONC validation"
  missing_file="$PWD/.missing-jsonc-file"

  run node tests/jsonc/validate-jsonc.js "$missing_file"

  assert_failure
  assert_output --partial "failed to read JSONC file: $missing_file"
}

@test "negative file match assertion fails on grep errors" {
  run assert_file_not_matches '[' "$(variant_file openai-chatgpt opencode.json)"

  assert_failure
  assert_output --partial "grep failed while searching"
}

@test "openai-chatgpt variant does not reference non-OpenAI model providers" {
  run assert_file_not_matches 'zai-coding-plan|google/|anthropic/|github-copilot/|opencode-go/|vercel/|kimi-for-coding/|moonshotai|aihubmix|ollama-cloud|firmware|venice/' "$(variant_file openai-chatgpt oh-my-openagent.jsonc)"
  assert_success
}

@test "Oh My OpenAgent variants use a shell-safe git-master env prefix" {
  for variant in zai-coding-plan openai-chatgpt; do
    run assert_file_matches '"git_env_prefix": "GIT_MASTER=1"' "$(variant_file "$variant" oh-my-openagent.jsonc)"
    assert_success
  done
}

@test "openai-chatgpt variant uses expected OmO OpenAI-only models with documented substitutions" {
  file="$(variant_file openai-chatgpt oh-my-openagent.jsonc)"

  run assert_file_matches 'openai/gpt-5\.5' "$file"
  assert_success

  run assert_file_matches 'openai/gpt-5\.4-mini' "$file"
  assert_success

  run assert_file_matches 'openai/gpt-5\.4' "$file"
  assert_success

  run assert_file_not_matches '"model": "openai/gpt-5\.3-codex"' "$file"
  assert_success

  run assert_file_matches 'openai/gpt-5\.3-codex-spark' "$file"
  assert_success

  run assert_file_not_matches '"model": "openai/gpt-5\.4-mini-fast"' "$file"
  assert_success

  run assert_file_matches 'gpt-5\.4-mini-fast is substituted with openai/gpt-5\.4-mini' "$file"
  assert_success

  run assert_file_matches 'gpt-5\.3-codex.*use openai/gpt-5\.4' "$file"
  assert_success
}

@test "openai-chatgpt variant keeps OpenCode config on OmO plugin without API key requirement" {
  run jq -e '.plugin | index("oh-my-openagent")' "$(variant_file openai-chatgpt opencode.json)"
  assert_success

  run assert_file_not_matches 'OPENAI_API_KEY|apiKey' "$(variant_file openai-chatgpt opencode.json)"
  assert_success
}

@test "OpenCode configs enable built-in LSPs and custom Markdown LSP" {
  for file in \
    bootstrap/config/variants/openai-chatgpt/opencode.json \
    bootstrap/config/variants/zai-coding-plan/opencode.json; do
    run jq -e '
      (.lsp | type) == "object"
      and .lsp.markdown.command == ["marksman", "server"]
      and .lsp.markdown.extensions == [".md", ".markdown"]
    ' "$file"
    assert_success
  done
}

@test "openai-chatgpt variant enables vue-language-server" {
  run jq -e '
    .lsp.vue.command == ["vue-language-server", "--stdio"]
    and .lsp.vue.extensions == [".vue"]
  ' bootstrap/config/variants/openai-chatgpt/opencode.json
  assert_success
}
