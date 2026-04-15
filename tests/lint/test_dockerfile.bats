@test "Dockerfile exists" {
  [ -f Dockerfile ]
}

@test "Dockerfile uses pinned debian:12.13-slim base" {
  grep -q 'debian:12.13-slim' Dockerfile
}

@test "Dockerfile creates opencode user" {
  grep -q 'useradd.*opencode' Dockerfile
}

@test "Dockerfile does NOT set USER opencode (entrypoint handles user switch)" {
  ! grep -q '^USER opencode' Dockerfile
}

@test "Dockerfile sets ENTRYPOINT" {
  grep -q 'ENTRYPOINT' Dockerfile
}

@test "Dockerfile sets CMD" {
  grep -q 'CMD.*\["web"\]' Dockerfile
}

@test "Dockerfile uses BuildKit cache mount for apt and at least two language package managers" {
  cache_mounts=$(grep -c 'mount=type=cache' Dockerfile)
  [ "$cache_mounts" -ge 3 ]
}

@test "Dockerfile has OPENCODE_VERSION build arg" {
  grep -q 'ARG OPENCODE_VERSION=' Dockerfile
}

@test "Dockerfile installs OpenCode with pinned version" {
  grep -q 'opencode-ai@\${OPENCODE_VERSION}' Dockerfile
}

@test "Dockerfile installs OmO" {
  grep -q 'oh-my-opencode' Dockerfile
}

@test "Dockerfile creates /opt/opencode-defaults" {
  grep -q 'opencode-defaults' Dockerfile
}

@test ".dockerignore exists" {
  [ -f .dockerignore ]
}

@test ".dockerignore excludes .env" {
  grep -q '^.env' .dockerignore
}

@test ".dockerignore excludes .git" {
  grep -q '^.git$' .dockerignore
}

@test ".dockerignore excludes tests/" {
  grep -q '^tests/' .dockerignore
}
