@test "docker-compose.yml is valid YAML" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose config > /dev/null
}

@test "docker-compose.yml has no named volumes section" {
  ! grep -q "^volumes:" docker-compose.yml
}

@test "docker-compose.yml has config bind mount under data/" {
  grep -q './data/config:/home/opencode/.config/opencode' docker-compose.yml
}

@test "docker-compose.yml has share bind mount under data/" {
  grep -q './data/share:/home/opencode/.local/share/opencode' docker-compose.yml
}

@test "docker-compose.yml has state bind mount under data/" {
  grep -q './data/state:/home/opencode/.local/state/opencode' docker-compose.yml
}

@test "docker-compose.yml has workspace bind mount under data/" {
  grep -q './data/workspace:/home/opencode/workspace' docker-compose.yml
}

@test "docker-compose.yml has skills bind mount (read-write)" {
  grep -q './data/skills:/home/opencode/.config/opencode/skills' docker-compose.yml
}

@test "skills mount is NOT read-only" {
  ! grep -q './data/skills:.*:ro' docker-compose.yml
}

@test "skills mount targets .config/opencode/skills (not /skills)" {
  grep -q '/home/opencode/.config/opencode/skills' docker-compose.yml
  ! grep -q '/home/opencode/skills:' docker-compose.yml
}

@test "ZHIPU_API_KEY is required (compose errors if missing)" {
  run bash -c 'ZHIPU_API_KEY= docker compose config 2>&1'
  [ "$status" -ne 0 ]
}

@test "GEMINI_API_KEY is optional (compose does NOT error if missing)" {
  run bash -c 'ZHIPU_API_KEY=test docker compose config 2>&1'
  [ "$status" -eq 0 ]
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

@test "healthcheck uses IPv4 loopback instead of localhost" {
  grep -q '127.0.0.1:\${OPENCODE_PORT:-4000}/health' docker-compose.yml
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
