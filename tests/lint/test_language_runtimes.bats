@test "Dockerfile installs Python via pyenv" {
  grep -q "pyenv" Dockerfile
}

@test "Dockerfile installs Node.js via nvm" {
  grep -q "nvm" Dockerfile
}

@test "Dockerfile installs Go from official tarball" {
  grep -q "go.dev\|golang.org" Dockerfile
}

@test "Dockerfile installs Rust via rustup" {
  grep -q "rustup" Dockerfile
}

@test "Dockerfile installs PHP via sury.org" {
  grep -q "sury.org\|sury" Dockerfile
}

@test "Dockerfile installs Bun" {
  grep -q "bun" Dockerfile
}

@test "Dockerfile has INSTALL_JAVA build arg" {
  grep -q "ARG INSTALL_JAVA" Dockerfile
}

@test "Dockerfile has INSTALL_RUBY build arg" {
  grep -q "ARG INSTALL_RUBY" Dockerfile
}

@test "Dockerfile has INSTALL_SWIFT build arg" {
  grep -q "ARG INSTALL_SWIFT" Dockerfile
}

@test "Dockerfile has INSTALL_ELIXIR build arg" {
  grep -q "ARG INSTALL_ELIXIR" Dockerfile
}

@test "Dockerfile installs Composer" {
  grep -q "composer" Dockerfile
}

@test "Dockerfile installs golangci-lint" {
  grep -q "golangci-lint" Dockerfile
}

@test "Dockerfile has conditional Java install" {
  grep -q 'INSTALL_JAVA.*true' Dockerfile
}

@test "Dockerfile has conditional Ruby install" {
  grep -q 'INSTALL_RUBY.*true' Dockerfile
}

@test "Dockerfile has conditional Swift install" {
  grep -q 'INSTALL_SWIFT.*true' Dockerfile
}

@test "Dockerfile has conditional Elixir install" {
  grep -q 'INSTALL_ELIXIR.*true' Dockerfile
}
