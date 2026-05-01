@test "docker-compose.yml exists" {
  [ -f docker-compose.yml ]
}

@test "docker-compose.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test \
    GIT_AUTHOR_NAME= \
    GIT_AUTHOR_EMAIL= \
    GIT_COMMITTER_NAME= \
    GIT_COMMITTER_EMAIL= \
    docker compose config > /dev/null
}

@test "docker-compose.docker.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose -f docker-compose.yml -f docker-compose.docker.yml config > /dev/null
}

@test "docker-compose.tunnel.yml file exists" {
  [ -f docker-compose.tunnel.yml ]
}

@test "docker-compose.tunnel.yml validates with docker compose config (quick profile)" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose -f docker-compose.yml -f docker-compose.tunnel.yml --profile quick config > /dev/null
}

@test "docker-compose.tunnel.yml validates with docker compose config (managed profile)" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test CF_TUNNEL_TOKEN=test docker compose -f docker-compose.yml -f docker-compose.tunnel.yml --profile managed config > /dev/null
}

@test "docker-compose.tunnel.yml does not require CF_TUNNEL_TOKEN for quick profile" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  ZHIPU_API_KEY=test docker compose -f docker-compose.yml -f docker-compose.tunnel.yml --profile quick config > /dev/null
}
