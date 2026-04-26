@test "docker-compose.yml exists" {
  [ -f docker-compose.yml ]
}

@test "docker-compose.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose config > /dev/null
}

@test "docker-compose.docker.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose -f docker-compose.yml -f docker-compose.docker.yml config > /dev/null
}
