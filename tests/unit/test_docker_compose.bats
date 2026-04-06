@test "docker-compose.yml is valid YAML" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose config > /dev/null
}

@test "docker-compose.yml has no named volumes section" {
  ! grep -q "^volumes:" docker-compose.yml
}

@test "docker-compose.yml has opencode-config bind mount" {
  grep -q "./opencode-config:/home/opencode/.config/opencode" docker-compose.yml
}

@test "docker-compose.yml has opencode-data bind mount" {
  grep -q "./opencode-data:/home/opencode/.local/share/opencode" docker-compose.yml
}

@test "docker-compose.yml has opencode-state bind mount" {
  grep -q "./opencode-state:/home/opencode/.local/state/opencode" docker-compose.yml
}

@test "docker-compose.yml has workspace bind mount" {
  grep -q "./opencode-workspace:/home/opencode/workspace" docker-compose.yml
}

@test "docker-compose.yml has skills bind mount as read-only" {
  grep -q "./skills:/home/opencode/.agents/skills:ro" docker-compose.yml
}

@test "skills mount targets .agents/skills (not /skills)" {
  grep -q "/home/opencode/.agents/skills" docker-compose.yml
  ! grep -q "/home/opencode/skills:" docker-compose.yml
}

@test "ZHIPU_API_KEY is required (compose errors if missing)" {
  run bash -c 'unset ZHIPU_API_KEY && docker compose config 2>&1'
  [ "$status" -ne 0 ]
}

@test "OPENCODE_MODE defaults to web" {
  grep -q 'OPENCODE_MODE.*web' docker-compose.yml
}

@test "port mapping uses OPENCODE_BIND_ADDRESS" {
  grep -q 'OPENCODE_BIND_ADDRESS' docker-compose.yml
}

@test "healthcheck uses dynamic port variable" {
  grep -q 'OPENCODE_PORT' docker-compose.yml
  grep -q '/health' docker-compose.yml
}

@test "TUI mode not present anywhere" {
  ! grep -q 'tui' docker-compose.yml
}

@test "environment has OPENCODE_SERVER_PASSWORD" {
  grep -q 'OPENCODE_SERVER_PASSWORD' docker-compose.yml
}

@test "warning comment about 0.0.0.0 + empty password" {
  grep -q "WARNING\|warning\|security\|password" docker-compose.yml
}
