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

@test "Dockerfile has comment about OmO RUN line requirements" {
  grep -B3 "bunx oh-my-opencode" Dockerfile | grep -qi "shell form\|Do not convert\|HOME\|temp\|--no-tui"
}

@test "Dockerfile has only one FROM directive" {
  from_count=$(grep -c "^FROM" Dockerfile)
  [ "$from_count" -eq 1 ]
}
