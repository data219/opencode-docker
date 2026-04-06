@test "docker-compose.yml exists" {
  [ -f docker-compose.yml ]
}

@test "docker-compose.yml uses ZHIPU_API_KEY with :? required" {
  grep -q 'ZHIPU_API_KEY:?ZHIPU_API_KEY is required' docker-compose.yml
}

@test "docker-compose.yml has healthcheck" {
  grep -q 'healthcheck:' docker-compose.yml
}

@test "healthcheck uses dynamic port variable" {
  # OPENCODE_PORT appears in healthcheck URL
  grep -q 'OPENCODE_PORT' docker-compose.yml
}

@test "docker-compose.yml binds config volume" {
  grep -q 'opencode-config' docker-compose.yml
}

@test "docker-compose.yml binds skills volume as read-only" {
  grep -q 'skills.*:ro' docker-compose.yml
}

@test "docker-compose.yml uses OPENCODE_BIND_ADDRESS for host port" {
  grep -q 'OPENCODE_BIND_ADDRESS' docker-compose.yml
}

@test "docker-compose.yml has restart policy" {
  grep -q 'restart:' docker-compose.yml
}

@test "docker-compose.yml has start_period for healthcheck" {
  grep -q 'start_period' docker-compose.yml
}

@test ".env.example has OPENCODE_BIND_ADDRESS default" {
  grep -q 'OPENCODE_BIND_ADDRESS' .env.example
}
