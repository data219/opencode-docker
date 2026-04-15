jsonc() {
  grep -v '^[[:space:]]*//' "$1" | jq .
}

@test "opencode.json is valid JSON" {
  run jq . bootstrap/config/opencode.json
  [ "$status" -eq 0 ]
}

@test "oh-my-openagent.jsonc is valid JSONC" {
  run jsonc bootstrap/config/oh-my-openagent.jsonc
  [ "$status" -eq 0 ]
}
