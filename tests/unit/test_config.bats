@test "opencode.json is valid JSON" {
  run jq . config/opencode.json
  [ "$status" -eq 0 ]
}

@test "opencode.json has provider.zai-coding-plan.api_key with env syntax" {
  run jq -r '.provider."zai-coding-plan".api_key' config/opencode.json
  [ "$status" -eq 0 ]
  [ "$output" = "{env:ZHIPU_API_KEY}" ]
}

@test "opencode.json has oh-my-opencode plugin" {
  run jq '.plugins[] | select(. == "oh-my-opencode")' config/opencode.json
  [ "$status" -eq 0 ]
}

@test "opencode.json does NOT use shell variable syntax" {
  ! grep -q '\${' config/opencode.json
}

@test "opencode.json has zai-coding-plan provider" {
  jq -e '.provider["zai-coding-plan"]' config/opencode.json > /dev/null
}

@test "opencode.json does NOT contain version comment" {
  ! grep -q 'opencode-docker-config' config/opencode.json
}

@test "opencode.json uses {env:ZHIPU_API_KEY} syntax" {
  grep -q '{env:ZHIPU_API_KEY}' config/opencode.json
}

@test "oh-my-openagent.jsonc has version comment" {
  head -1 config/oh-my-openagent.jsonc | grep -q 'opencode-docker-config'
}

@test "oh-my-openagent.jsonc is valid JSONC (valid JSON minus comments)" {
  grep -v '^\s*//' config/oh-my-openagent.jsonc | jq . > /dev/null
}

# Helper: strip JSONC comments before jq
jsonc() {
  grep -v '^\s*//' "$1" | jq -r "$2"
}

@test "oh-my-openagent.jsonc assigns GLM-5 to sisyphus" {
  run jsonc config/oh-my-openagent.jsonc '.agents.sisyphus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5" ]
}

@test "oh-my-openagent.jsonc assigns GLM-5 to prometheus" {
  run jsonc config/oh-my-openagent.jsonc '.agents.prometheus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5" ]
}

@test "oh-my-openagent.jsonc assigns GLM-5 to metis" {
  run jsonc config/oh-my-openagent.jsonc '.agents.metis.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5" ]
}

@test "oh-my-openagent.jsonc assigns GLM-5 to oracle" {
  run jsonc config/oh-my-openagent.jsonc '.agents.oracle.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5" ]
}

@test "oh-my-openagent.jsonc assigns GLM-5 to momus" {
  run jsonc config/oh-my-openagent.jsonc '.agents.momus.model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-5" ]
}

@test "oh-my-openagent.jsonc assigns GLM-4.6v to multimodal-looker" {
  run jsonc config/oh-my-openagent.jsonc '.agents."multimodal-looker".model'
  [ "$status" -eq 0 ]
  [ "$output" = "zai-coding-plan/glm-4.6v" ]
}

@test "oh-my-openagent.jsonc does NOT assign GLM to hephaestus" {
  ! grep -v '^\s*//' config/oh-my-openagent.jsonc | jq -e '.agents.hephaestus' 2>/dev/null
}

@test "oh-my-openagent.jsonc has config version comment" {
  grep -q "opencode-docker-config:1" config/oh-my-openagent.jsonc
}

@test ".opencode-docker-config-version exists" {
  [ -f config/.opencode-docker-config-version ]
}

@test ".opencode-docker-config-version contains version number" {
  content=$(cat config/.opencode-docker-config-version)
  [ "$content" = "1" ]
}

@test "no auth.json file exists" {
  [ ! -f config/auth.json ]
  [ ! -f auth.json ]
  ! grep -q "auth.json" Dockerfile
}
