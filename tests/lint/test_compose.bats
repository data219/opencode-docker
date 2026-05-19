compose_config() {
  env \
    -u COMPOSE_FILE \
    -u COMPOSE_PROJECT_NAME \
    -u COMPOSE_PROFILES \
    -u DOCKER_HOST \
    -u OPENCODE_DOCKER_SOCKET_BIND \
    -u OPENCODE_DOCKER_SOCKET \
    -u CF_TUNNEL_TOKEN \
    -u CF_TUNNEL_TARGET_HOST \
    -u CF_TUNNEL_TARGET_PORT \
    -u OPENCODE_PORT \
    "$@" \
    docker compose --env-file /dev/null -f docker-compose.yml config
}

@test "docker-compose.yml exists" {
  [ -f docker-compose.yml ]
}

@test "docker-compose.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  compose_config \
    OCD_ZHIPU_API_KEY=test \
    GIT_AUTHOR_NAME= \
    GIT_AUTHOR_EMAIL= \
    GIT_COMMITTER_NAME= \
    GIT_COMMITTER_EMAIL= > /dev/null
}

@test "docker-compose.yml validates quick tunnel profile" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  compose_config \
    OCD_ZHIPU_API_KEY=test \
    COMPOSE_PROFILES=tunnel-quick > /dev/null
}

@test "docker-compose.yml validates managed tunnel profile" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  compose_config \
    OCD_ZHIPU_API_KEY=test \
    CF_TUNNEL_TOKEN=test \
    COMPOSE_PROFILES=tunnel-managed > /dev/null
}

@test "quick tunnel profile does not require CF_TUNNEL_TOKEN" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  compose_config \
    OCD_ZHIPU_API_KEY=test \
    COMPOSE_PROFILES=tunnel-quick > /dev/null
}

@test "docker socket env renders host docker socket mount" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  run compose_config \
    OCD_ZHIPU_API_KEY=test \
    OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock

  [ "$status" -eq 0 ]
  [[ "$output" == *"source: /var/run/docker.sock"* ]]
  [[ "$output" == *"target: /var/run/docker.sock"* ]]
  [[ "$output" == *"OPENCODE_DOCKER_SOCKET: /var/run/docker.sock"* ]]
  [[ "$output" == *"DOCKER_HOST: unix:///var/run/docker.sock"* ]]
}

@test "ambient DOCKER_HOST alone does not enable docker host env" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  run compose_config \
    OCD_ZHIPU_API_KEY=test \
    DOCKER_HOST=tcp://docker.example:2375

  [ "$status" -eq 0 ]
  [[ "$output" != *"DOCKER_HOST: tcp://docker.example:2375"* ]]
  [[ "$output" == *"DOCKER_HOST: \"\""* ]]
}

@test "legacy OPENCODE_DOCKER_SOCKET alone does not enable docker socket env" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  run compose_config \
    OCD_ZHIPU_API_KEY=test \
    OPENCODE_DOCKER_SOCKET=/var/run/docker.sock

  [ "$status" -eq 0 ]
  [[ "$output" != *"OPENCODE_DOCKER_SOCKET: /var/run/docker.sock"* ]]
  [[ "$output" == *"OPENCODE_DOCKER_SOCKET: \"\""* ]]
}
