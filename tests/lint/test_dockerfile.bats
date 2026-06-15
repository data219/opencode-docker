load ../test_helper

node_install_block() {
  awk '
    /^# --- Install Node\.js for OpenCode ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

java_install_block() {
  awk '
    /^# --- Optional: Java \(Temurin JDK 21\) ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

rust_install_block() {
  awk '
    /^# --- Optional: Rust via rustup ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

go_install_block() {
  awk '
    /^# --- Install Go directly from go\.dev ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

golangci_lint_install_block() {
  awk '
    /^# --- Install golangci-lint ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

omo_install_block() {
  awk '
    /^# --- Install Oh-My-OpenAgent ---$/ { in_block = 1 }
    in_block { print }
    in_block && /^$/ { exit }
  ' Dockerfile
}

@test "Dockerfile does not contain known hardcoded architecture download paths" {
  run grep -En 'node-v\$\{NODE_VERSION\}-linux-x64|go\$\{GO_VERSION\}\.linux-amd64|golangci-lint-\$\{GO_LINT_VERSION\}-linux-amd64|OpenJDK21U-jdk_x64_linux_hotspot|rustup/archive/\$\{RUSTUP_VERSION\}/x86_64-unknown-linux-gnu/rustup-init|bun-linux-x64' Dockerfile

  assert_failure
  assert_output ""
}

@test "Node.js install chooses archive architecture dynamically" {
  run node_install_block
  assert_success
  refute_output --partial "node-v\${NODE_VERSION}-linux-x64.tar.xz"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) node_arch="x64"'
  assert_output --partial 'arm64) node_arch="arm64"'
  assert_output --partial 'node-v${NODE_VERSION}-linux-${node_arch}.tar.xz'
}

@test "Java install chooses Temurin archive architecture dynamically" {
  run java_install_block
  assert_success
  refute_output --partial "OpenJDK21U-jdk_x64_linux_hotspot"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) java_arch="x64"'
  assert_output --partial 'arm64) java_arch="aarch64"'
  assert_output --partial 'OpenJDK21U-jdk_${java_arch}_linux_hotspot_${JAVA_ARCHIVE_VERSION}.tar.gz'
}

@test "Rust install chooses rustup host dynamically" {
  run rust_install_block
  assert_success
  refute_output --partial "rustup/archive/\${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) rustup_host="x86_64-unknown-linux-gnu"'
  assert_output --partial 'arm64) rustup_host="aarch64-unknown-linux-gnu"'
  assert_output --partial 'rustup/archive/${RUSTUP_VERSION}/${rustup_host}/rustup-init'
}

@test "Go install chooses archive architecture dynamically" {
  run go_install_block
  assert_success
  refute_output --partial "go\${GO_VERSION}.linux-amd64.tar.gz"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) go_arch="amd64"'
  assert_output --partial 'arm64) go_arch="arm64"'
  assert_output --partial 'go${GO_VERSION}.linux-${go_arch}.tar.gz'
}

@test "golangci-lint install chooses archive architecture dynamically" {
  run golangci_lint_install_block
  assert_success
  refute_output --partial "golangci-lint-\${GO_LINT_VERSION}-linux-amd64"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) common_arch="amd64"'
  assert_output --partial 'arm64) common_arch="arm64"'
  assert_output --partial 'golangci-lint-${GO_LINT_VERSION}-linux-${common_arch}.tar.gz'
}

@test "Oh-My-OpenAgent Bun install chooses archive architecture dynamically" {
  run omo_install_block
  assert_success
  refute_output --partial "bun-linux-x64.zip"
  refute_output --partial "/tmp/bun-linux-x64"
  assert_output --partial 'arch="$(dpkg --print-architecture)"'
  assert_output --partial 'amd64) bun_arch="x64"'
  assert_output --partial 'arm64) bun_arch="aarch64"'
  assert_output --partial 'bun-linux-${bun_arch}.zip'
  assert_output --partial '/tmp/bun-linux-${bun_arch}/bun'
}
