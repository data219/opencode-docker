@test "Dockerfile has no multi-stage AS directives" {
  ! grep -qE "FROM.*AS" Dockerfile
}

@test "Dockerfile uses BuildKit cache mount for apt" {
  grep -q 'mount=type=cache,target=/var/cache/apt' Dockerfile
}

@test "Dockerfile uses BuildKit cache mount for apt and at least two language package managers" {
  cache_mounts=$(grep -c 'mount=type=cache' Dockerfile)
  [ "$cache_mounts" -ge 3 ]
}

@test "Dockerfile has shell-form comment on OmO RUN line" {
  grep -B1 "bunx oh-my-opencode" Dockerfile | grep -q "Shell form required"
}

@test "Dockerfile has only one FROM directive" {
  from_count=$(grep -c "^FROM" Dockerfile)
  [ "$from_count" -eq 1 ]
}
