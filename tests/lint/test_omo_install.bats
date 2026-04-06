@test "Dockerfile has OMO_VERSION build arg defaulting to 3.14.0" {
  grep -q 'ARG OMO_VERSION=3.14.0' Dockerfile
}

@test "Dockerfile runs OmO installer with --no-tui" {
  grep -q "oh-my-opencode.*install.*--no-tui" Dockerfile
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
  grep -qE "^RUN bunx oh-my-opencode" Dockerfile
}

@test "Dockerfile COPYs config files into image" {
  grep -q "COPY.*opencode.json" Dockerfile
  grep -q "COPY.*oh-my-openagent.jsonc" Dockerfile
}

@test "Dockerfile COPYs opencode.json to /opt/opencode-defaults/" {
  grep -q 'COPY.*opencode.json.*/opt/opencode-defaults/' Dockerfile
}

@test "Dockerfile COPYs oh-my-openagent.jsonc to /opt/opencode-defaults/" {
  grep -q 'COPY.*oh-my-openagent.jsonc.*/opt/opencode-defaults/' Dockerfile
}

@test "Dockerfile COPYs .opencode-docker-config-version to /opt/opencode-defaults/" {
  grep -q 'COPY.*\.opencode-docker-config-version.*/opt/opencode-defaults/' Dockerfile
}
