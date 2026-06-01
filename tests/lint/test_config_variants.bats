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
  node -e '
    const fs = require("fs");
    const path = process.argv[1];
    const input = fs.readFileSync(path, "utf8")
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/(^|[^:])\/\/.*$/gm, "$1")
      .replace(/,\s*([}\]])/g, "$1");
    JSON.parse(input);
  ' "$file"
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

@test "zai-coding-plan variant mirrors current bootstrap config" {
  cmp -s bootstrap/config/opencode.json "$(variant_file zai-coding-plan opencode.json)"
  cmp -s bootstrap/config/oh-my-openagent.jsonc "$(variant_file zai-coding-plan oh-my-openagent.jsonc)"
}

@test "openai-chatgpt variant does not reference non-OpenAI model providers" {
  run rg -n 'zai-coding-plan|google/|anthropic/|github-copilot/|opencode-go/|vercel/|kimi-for-coding/|moonshotai|aihubmix|ollama-cloud|firmware|venice/' "$(variant_file openai-chatgpt oh-my-openagent.jsonc)"
  [ "$status" -eq 1 ]
}

@test "openai-chatgpt variant uses expected OmO OpenAI-only models with documented substitution" {
  file="$(variant_file openai-chatgpt oh-my-openagent.jsonc)"

  run rg -n 'openai/gpt-5\.5' "$file"
  assert_success

  run rg -n 'openai/gpt-5\.4-mini' "$file"
  assert_success

  run rg -n 'openai/gpt-5\.3-codex' "$file"
  assert_success

  run rg -n '"model": "openai/gpt-5\.4-mini-fast"' "$file"
  [ "$status" -eq 1 ]

  run rg -n 'gpt-5\.4-mini-fast is substituted with openai/gpt-5\.4-mini' "$file"
  assert_success
}

@test "openai-chatgpt variant keeps OpenCode config on OmO plugin without API key requirement" {
  run jq -e '.plugin | index("oh-my-openagent")' "$(variant_file openai-chatgpt opencode.json)"
  assert_success

  run rg -n 'OPENAI_API_KEY|apiKey' "$(variant_file openai-chatgpt opencode.json)"
  [ "$status" -eq 1 ]
}
