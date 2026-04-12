@test "Dockerfile has OMO_VERSION build arg defaulting to 3.14.0" {
  grep -q 'ARG OMO_VERSION=3.14.0' Dockerfile
}

@test "Dockerfile OmO install uses --no-tui (required for non-interactive Docker build)" {
  grep -q "oh-my-opencode.*install" Dockerfile && grep -q "\-\-no-tui" Dockerfile
}

@test "Dockerfile runs OmO installer with --zai-coding-plan=yes" {
  grep -q -- "--zai-coding-plan=yes" Dockerfile
}

@test "Dockerfile disables claude, openai, gemini, copilot in OmO installer" {
  grep -q -- "--claude=no" Dockerfile
  grep -q -- "--openai=no" Dockerfile
  grep -q -- "--gemini=no" Dockerfile
  grep -q -- "--copilot=no" Dockerfile
}

@test "Dockerfile uses shell form for OmO RUN line" {
  grep -A1 "^RUN mkdir -p /opt/opencode-defaults" Dockerfile | head -4 | grep -q "oh-my-opencode"
}

@test "Dockerfile provides oh-my-openagent config" {
  grep -q "oh-my-openagent" Dockerfile
}

@test "Dockerfile COPYs opencode.json to /opt/opencode-defaults/" {
  grep -q 'COPY.*opencode.json.*/opt/opencode-defaults/' Dockerfile
}

@test "Dockerfile seeds OmO agent config into /opt/opencode-defaults/" {
  grep -q "oh-my-openagent.*opt/opencode-defaults" Dockerfile
}

@test "Dockerfile COPYs .opencode-docker-config-version to /opt/opencode-defaults/" {
  grep -q 'COPY.*\.opencode-docker-config-version.*/opt/opencode-defaults/' Dockerfile
}
