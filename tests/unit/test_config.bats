@test "opencode.json is valid JSON" {
  run jq . bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
}

@test "opencode.json uses correct plugin key (singular)" {
  jq -e '.plugin' bootstrap/config/opencode.json > /dev/null
}

@test "opencode.json has oh-my-openagent plugin" {
  run jq '.plugin[] | select(. == "oh-my-openagent")' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
}

@test "opencode.json does NOT use legacy plugins key (plural)" {
  ! jq -e '.plugins' bootstrap/config/opencode.json 2>/dev/null
}

@test "opencode.json has provider with options.apiKey using env syntax" {
  run jq -r '.provider."zai-coding-plan".options.apiKey' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
  [ "$output" = "{env:ZHIPU_API_KEY}" ]
}

@test "opencode.json has provider options.baseURL" {
  run jq -r '.provider."zai-coding-plan".options.baseURL' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
  [[ "$output" == *"z.ai"* ]]
}

@test "opencode.json has schema reference" {
  grep -q "opencode.ai/config.json" bootstrap/config/opencode.json
}

@test "opencode.json does NOT contain version comment" {
  ! grep -q 'opencode-docker-config' bootstrap/config/opencode.json
}

@test "opencode.json does NOT use shell variable syntax" {
  ! grep -q '\${' bootstrap/config/opencode.json
}

@test "opencode.json declares all 4 GLM models" {
  run jq -r '.provider."zai-coding-plan".models | keys[]' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "glm-4.5-air" ]
  [ "${lines[1]}" = "glm-4.7" ]
  [ "${lines[2]}" = "glm-5-turbo" ]
  [ "${lines[3]}" = "glm-5.1" ]
}

@test "opencode.json models have correct context limits" {
  run jq -r '.provider."zai-coding-plan".models."glm-5.1".limit.context' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
  [ "$output" = "200000" ]
  run jq -r '.provider."zai-coding-plan".models."glm-4.5-air".limit.context' bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
  [ "$output" = "128000" ]
}

@test "oh-my-openagent.jsonc has version comment" {
  head -1 bootstrap/config/oh-my-openagent.jsonc | grep -q 'opencode-docker-config'
}

@test "oh-my-openagent.jsonc is valid JSONC (valid JSON minus comments)" {
  grep -v '^\s*//' bootstrap/config/oh-my-openagent.jsonc | jq . > /dev/null
}

# Helper: strip JSONC comments before jq
jsonc() {
  grep -v '^\s*//' "$1" | jq -r "$2"
}

@test "oh-my-openagent.jsonc assigns glm-5.1 to sisyphus" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents.sisyphus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5.1" ]
}

@test "oh-my-openagent.jsonc assigns glm-5-turbo to hephaestus" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents.hephaestus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5-turbo" ]
}

@test "oh-my-openagent.jsonc assigns glm-5.1 to prometheus" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents.prometheus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5.1" ]
}

@test "oh-my-openagent.jsonc assigns glm-4.7 to atlas" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents.atlas.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-4.7" ]
}

@test "oh-my-openagent.jsonc assigns glm-4.5-air to explore" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents.explore.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-4.5-air" ]
}

@test "oh-my-openagent.jsonc assigns glm-4.7 to multimodal-looker" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents."multimodal-looker".model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-4.7" ]
}

@test "oh-my-openagent.jsonc assigns glm-5-turbo to sisyphus-junior" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents."sisyphus-junior".model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5-turbo" ]
}

@test "oh-my-openagent.jsonc configures all 11 agents" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.agents | keys | length'
  [ "$status" -eq 0 ]
  [ "$output" = "11" ]
}

@test "oh-my-openagent.jsonc configures all 8 categories" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc '.categories | keys | length'
  [ "$status" -eq 0 ]
  [ "$output" = "8" ]
}

@test "oh-my-openagent.jsonc has config version comment" {
  grep -q "opencode-docker-config:1" bootstrap/config/oh-my-openagent.jsonc
}

@test ".opencode-docker-config-version exists" {
  [ -f bootstrap/config/.opencode-docker-config-version ]
}

@test ".opencode-docker-config-version contains version number" {
  content=$(cat bootstrap/config/.opencode-docker-config-version)
  [ "$content" = "3" ]
}

@test "no auth.json file exists" {
  [ ! -f bootstrap/config/auth.json ]
  [ ! -f auth.json ]
  ! grep -q "auth.json" Dockerfile
}
