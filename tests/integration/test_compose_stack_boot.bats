load ../test_helper

setup() {
  TEST_COMPOSE_PROJECT="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_CONTAINER_NAME="opencode-stack-boot-${BATS_TEST_NUMBER}-$$"
  TEST_OPENCODE_PORT="${TEST_OPENCODE_PORT:-$((4100 + ($$ % 2000) + BATS_TEST_NUMBER))}"
  TEST_HEALTH_TIMEOUT="${TEST_HEALTH_TIMEOUT:-300}"
  TEST_STACK_START_ATTEMPTS="${TEST_STACK_START_ATTEMPTS:-2}"
  TEST_HOME_ROOT=""
}

emit_test_diag() {
  local output

  output="$("$@" 2>&1 || true)"
  [ -n "$output" ] && printf "%s\n" "$output" >&3
  [ -n "$output" ] && printf "%s\n" "$output" >&2
}

prepare_test_stack() {
  TEST_OPENCODE_PORT="${1:-$TEST_OPENCODE_PORT}"
  TEST_HOME_ROOT="$(mktemp -d "${PWD}/.test-home.XXXXXX")"

  export OCD_ZHIPU_API_KEY="test"
  export OCD_GEMINI_API_KEY=""
  export GIT_AUTHOR_NAME=""
  export GIT_AUTHOR_EMAIL=""
  export GIT_COMMITTER_NAME=""
  export GIT_COMMITTER_EMAIL=""
  export DOKPLOY_URL=""
  export DOKPLOY_API_KEY=""
  export OPENCODE_MODE="web"
  export OPENCODE_PORT="${TEST_OPENCODE_PORT}"
  export OPENCHAMBER_PORT="$((TEST_OPENCODE_PORT + 2000))"
  export OPENCODE_BIND_ADDRESS="127.0.0.1"
  export OPENCODE_CONTAINER_NAME="${TEST_CONTAINER_NAME}"
  export OPENCODE_HOME_DIR="${TEST_HOME_ROOT}"
  # Keep ambient tunnel profiles from starting real external services in tests.
  export COMPOSE_PROFILES=""

  chmod 0777 "${TEST_HOME_ROOT}"
}

teardown() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    down -v --remove-orphans >/dev/null 2>&1 || true
  if [ -d "$TEST_HOME_ROOT" ]; then
    docker run --rm \
      -v "${TEST_HOME_ROOT}:/mnt" \
      alpine sh -lc 'rm -rf /mnt/* /mnt/.[!.]* /mnt/..?* 2>/dev/null || true' \
      >/dev/null 2>&1 || true
  fi
  rm -rf "$TEST_HOME_ROOT"
}

compose_ci() {
  docker compose \
    -p "$TEST_COMPOSE_PROJECT" \
    "$@"
}

wait_for_http_health() {
  local url="$1"
  local timeout="${2:-120}"
  local interval=2
  local request_timeout="${TEST_HEALTH_REQUEST_TIMEOUT:-2}"
  local next_progress=30
  local start_time
  local elapsed

  start_time="$(date +%s)"

  while true; do
    elapsed=$(($(date +%s) - start_time))
    if [ "$elapsed" -ge "$timeout" ]; then
      return 1
    fi

    if curl --max-time "$request_timeout" -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if [ "$elapsed" -ge "$next_progress" ]; then
      echo "  [wait_for_http_health] ${elapsed}/${timeout}s waiting for $url" >&3
      echo "  [wait_for_http_health] ${elapsed}/${timeout}s waiting for $url" >&2
      next_progress=$((next_progress + 30))
    fi
    sleep "$interval"
  done
}

print_stack_diagnostics() {
  emit_test_diag compose_ci ps
  emit_test_diag compose_ci logs --tail=200 opencode
  emit_test_diag docker inspect \
    --format 'health={{json .State.Health}}' \
    "$TEST_CONTAINER_NAME"
  emit_test_diag compose_ci exec -T opencode sh -lc '
    echo "container-health-probe:"
    curl -sv --max-time 5 "http://127.0.0.1:${OPENCODE_PORT}/health"
  ' || true
}

start_test_stack() {
  run compose_ci up -d --build
  [ "$status" -eq 0 ]

  local attempt=1
  while [ "$attempt" -le "$TEST_STACK_START_ATTEMPTS" ]; do
    if wait_for_http_health "http://127.0.0.1:${OPENCODE_PORT}/health" "$TEST_HEALTH_TIMEOUT"; then
      return 0
    fi

    print_stack_diagnostics
    if [ "$attempt" -lt "$TEST_STACK_START_ATTEMPTS" ]; then
      echo "  [start_test_stack] health check timed out; restarting stack attempt $((attempt + 1))/${TEST_STACK_START_ATTEMPTS}" >&3
      echo "  [start_test_stack] health check timed out; restarting stack attempt $((attempt + 1))/${TEST_STACK_START_ATTEMPTS}" >&2
      compose_ci restart opencode >&3 || true
    fi
    attempt=$((attempt + 1))
  done

  false
}

@test "compose stack boots and serves health endpoint" {
  prepare_test_stack
  start_test_stack

  run curl -fsS "http://127.0.0.1:${OPENCODE_PORT}/health"
  [ "$status" -eq 0 ]
}

@test "compose stack loads OmO runtime config in opencode" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode test -f /home/opencode/.omo/omo.jsonc
  [ "$status" -eq 0 ]
  [ -f "${TEST_HOME_ROOT}/.omo/omo.jsonc" ]

  run compose_ci exec -T opencode test -f /home/opencode/.config/opencode/AGENTS.md
  [ "$status" -eq 0 ]
  [ -f "${TEST_HOME_ROOT}/.config/opencode/AGENTS.md" ]

  run compose_ci exec -T -u opencode opencode sh -lc 'opencode debug paths | grep -F "config     /home/opencode/.config/opencode"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v jq >/dev/null 2>&1 || {
      echo "ERROR: jq is required for OmO runtime config assertions but is not installed in the container." >&2
      exit 1
    }
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    config_dump="$(mktemp)"
    opencode debug config > "$config_dump"
    jq -e "
      .plugin | index(\"oh-my-openagent\")
    " "$config_dump" >/dev/null
    jq -e "
      any(
        .plugin_origins[];
        .spec == \"oh-my-openagent\"
        and .scope == \"global\"
      )
    " "$config_dump" >/dev/null
  '
  [ "$status" -eq 0 ]
}

@test "compose stack preserves configured OmO models in the active harness" {
  export OPENCODE_CONFIG_VARIANT="openai-chatgpt"
  prepare_test_stack
  start_test_stack

  local omo_version
  omo_version="$(awk -F= '$1 == "ARG OMO_VERSION" {print $2}' Dockerfile)"
  [ -n "$omo_version" ]

  run compose_ci exec -T -u opencode -e OMO_TEST_VERSION="$omo_version" opencode sh -c '
    doctor_dump="$(mktemp)"
    npx --yes "oh-my-opencode@${OMO_TEST_VERSION}" doctor --platform opencode --json > "$doctor_dump" || true
    jq -e '\''
      .target == "opencode"
      and .systemInfo.configValid == true
      and .systemInfo.pluginVersion == env.OMO_TEST_VERSION
      and .systemInfo.loadedVersion == env.OMO_TEST_VERSION
      and any(.results[];
        .name == "Configuration"
        and .status == "pass"
        and .message == "Configuration is valid"
      )
      and any(.results[];
        .name == "Models"
        and .status == "pass"
        and .message == "11 agents, 9 categories, 20 overrides"
        and (.details | map(
          sub("^\\s*[●○]\\s+"; "")
          | sub(" \\[capabilities: [^]]+\\]$"; "")
        ) | . as $details | all([
          "sisyphus: openai/gpt-6-sol (medium)",
          "hephaestus: openai/gpt-6-sol (medium)",
          "prometheus: openai/gpt-6-sol (high)",
          "metis: openai/gpt-6-sol (high)",
          "oracle: openai/gpt-6-astra (high)",
          "momus: openai/gpt-6-astra (xhigh)",
          "atlas: openai/gpt-6-sol (medium)",
          "sisyphus-junior: openai/gpt-6-sol (medium)",
          "explore: openai/gpt-6-luna (low)",
          "librarian: openai/gpt-6-luna (low)",
          "multimodal-looker: openai/gpt-6-sol (low)",
          "ultrabrain: openai/gpt-6-astra (max)",
          "visual-engineering: openai/gpt-6-sol (high)",
          "unspecified-high: openai/gpt-6-sol (high)",
          "deep-low: openai/gpt-6-sol (medium)",
          "deep-high: openai/gpt-6-astra (xhigh)",
          "writing: openai/gpt-6-sol (medium)",
          "quick: openai/gpt-6-luna (low)",
          "unspecified-low: openai/gpt-6-sol (high)",
          "artistry: openai/gpt-6-sol (xhigh)"
        ][]; . as $expected | any($details[]; . == $expected)))
      )
    '\'' "$doctor_dump" || { cat "$doctor_dump"; exit 1; }
  '
  [ "$status" -eq 0 ] || { printf "%s\n" "$output" >&2; return 1; }

  # Check the ordered fallback ladders exposed in OpenCode's effective agent config.
  run compose_ci exec -T -u opencode -e OPENAI_API_KEY=catalog-test-placeholder opencode sh -c '
    config_dump="$(mktemp)"
    opencode debug config > "$config_dump"
    jq -e '\''
      (.agent | with_entries(select(.value.fallback_models != null) | .value = .value.fallback_models)) == {
        "Sisyphus - ultraworker": ["openai/gpt-6-luna"],
        "Hephaestus - Deep Agent": ["openai/gpt-6-luna"],
        "Prometheus - Plan Builder": ["openai/gpt-6-luna"],
        "Atlas - Plan Executor": ["openai/gpt-6-luna"],
        "explore": ["openai/gpt-6-sol"],
        "librarian": ["openai/gpt-6-sol"],
        "Metis - Plan Consultant": ["openai/gpt-6-luna"],
        "Momus - Plan Critic": ["openai/gpt-6-sol", "openai/gpt-6-luna"],
        "multimodal-looker": ["openai/gpt-6-luna"],
        "oracle": ["openai/gpt-6-sol", "openai/gpt-6-luna"],
        "plan": ["openai/gpt-6-luna"]
      }
    '\'' "$config_dump" >/dev/null || {
      jq -c '\'' .agent | with_entries(select(.value.fallback_models != null) | .value = .value.fallback_models) '\'' "$config_dump"
      exit 1
    }
  '
  [ "$status" -eq 0 ] || { printf "%s\n" "$output" >&2; return 1; }
}

@test "compose stack preserves effective reasoning for Prometheus and Junior" {
  export OPENCODE_CONFIG_VARIANT="openai-chatgpt"
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T -u opencode -e OPENAI_API_KEY=catalog-test-placeholder opencode sh -c '
    for spec in "Prometheus - Plan Builder|high" "Sisyphus-Junior|medium"; do
      name="${spec%%|*}"
      effort="${spec#*|}"
      agent_dump="$(mktemp)"
      opencode debug agent "$name" > "$agent_dump"
      jq -e --arg effort "$effort" '\''
        .model.providerID == "openai"
        and .model.modelID == "gpt-6-sol"
        and .variant == $effort
      '\'' "$agent_dump" || { cat "$agent_dump"; exit 1; }
    done
  '
  [ "$status" -eq 0 ] || { printf "%s\n" "$output" >&2; return 1; }
}

@test "compose stack exposes GPT-6 standard models and reasoning efforts" {
  export OPENCODE_CONFIG_VARIANT="openai-chatgpt"
  prepare_test_stack
  start_test_stack

  # A dummy key makes the provider catalog visible without real credentials or inference.
  run compose_ci exec -T -u opencode -e OPENAI_API_KEY=catalog-test-placeholder opencode sh -c '
    model_dump="$(mktemp)"
    opencode models openai --refresh >/dev/null
    opencode models openai --verbose > "$model_dump"
    node - "$model_dump" <<\NODE
const fs = require("fs");
const raw = fs.readFileSync(process.argv[2], "utf8");
const models = new Map();
for (const part of raw.split(/(?=^openai\/)/m)) {
  const split = part.indexOf("\n");
  const id = part.slice(0, split);
  if (/^openai\/gpt-6-(astra|sol|luna)$/.test(id)) {
    models.set(id, JSON.parse(part.slice(split)));
  }
}
for (const name of ["astra", "sol", "luna"]) {
  const model = models.get(`openai/gpt-6-${name}`);
  if (!model) throw new Error(`Missing standard GPT-6 ${name} in runtime catalog`);
  if (model.options?.serviceTier === "priority") {
    throw new Error(`Standard GPT-6 ${name} must not use priority service`);
  }
  for (const effort of ["low", "medium", "high", "xhigh", "max"]) {
    if (model.variants?.[effort]?.reasoningEffort !== effort) {
      throw new Error(`GPT-6 ${name} does not expose ${effort} reasoning`);
    }
    if (model.variants[effort].serviceTier === "priority") {
      throw new Error(`Standard GPT-6 ${name} ${effort} variant must not use priority service`);
    }
  }
  console.log(`${model.id}: low/medium/high/xhigh/max supported, standard service`);
}
NODE
  '
  [ "$status" -eq 0 ] || { printf "%s\n" "$output" >&2; return 1; }
}

@test "compose stack provides bundled CLIs and defaults" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode sh -lc 'command -v agent-browser'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v gh'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v glab'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v cntb && cntb version'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v atlcli'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v dokploy && dokploy --help >/dev/null'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v cloudflared && cloudflared --version'
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc 'command -v rg && rg --version'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v openspec >/dev/null &&
    openspec --version >/dev/null &&
    project_dir="$(mktemp -d)" &&
    cd "$project_dir" &&
    git init >/dev/null &&
    openspec init --tools opencode >/tmp/openspec-init.log 2>&1 &&
    test -d .opencode/skills &&
    find .opencode/commands -type f -name "opsx-*.md" | grep -q .
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v php >/dev/null &&
    php --version >/dev/null &&
    command -v node >/dev/null &&
    node --version >/dev/null &&
    command -v npm >/dev/null &&
    npm --version >/dev/null &&
    command -v zsh >/dev/null &&
    zsh --version >/dev/null &&
    command -v python >/dev/null &&
    command -v python3 >/dev/null &&
    python --version >/dev/null &&
    python3 --version >/dev/null &&
    python -m pip --version >/dev/null &&
    python -m venv /tmp/opencode-python-smoke &&
    /tmp/opencode-python-smoke/bin/python -c "print(\"python-ready\")" &&
    command -v go >/dev/null &&
    go version >/dev/null &&
    ! command -v rustc >/dev/null &&
    ! test -d /opt/rustup/toolchains
  '
  [ "$status" -eq 0 ]
  [[ "$output" = *"python-ready"* ]]

  run compose_ci exec -T opencode test -f /opt/opencode-defaults/omo-generated-omo.jsonc
  [ "$status" -eq 0 ]
}

@test "compose stack provides OpenCode LSP server commands" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T -u opencode opencode sh -lc '
    for command in \
      intelephense \
      typescript-language-server \
      gopls \
      bash-language-server \
      vue-language-server \
      lua-language-server \
      pyright-langserver \
      terraform-ls \
      rust-analyzer \
      yaml-language-server \
      marksman; do
      command -v "$command" >/dev/null || {
        echo "missing $command" >&2
        exit 1
      }
    done
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '
    config_dump="$(mktemp)"
    opencode debug config > "$config_dump"
    jq -e "
      (.lsp | type) == \"object\"
      and .lsp.markdown.command == [\"marksman\", \"server\"]
      and .lsp.markdown.extensions == [\".md\", \".markdown\"]
    " "$config_dump" >/dev/null
  '
  [ "$status" -eq 0 ]
}

@test "compose stack keeps Rust toolchain optional while providing Rust LSP" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T -u opencode opencode sh -lc '
    command -v rust-analyzer >/dev/null &&
    ! command -v rustc >/dev/null &&
    ! test -d /opt/rustup/toolchains
  '
  [ "$status" -eq 0 ]
}

@test "compose stack validates agent-browser runtime and renders PDFs" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T -u opencode opencode sh -lc '
    test "$AGENT_BROWSER_EXECUTABLE_PATH" = "/opt/agent-browser/chrome/chrome" &&
    test -x "$AGENT_BROWSER_EXECUTABLE_PATH" &&
    if [ "$(dpkg --print-architecture)" = "arm64" ]; then
      test -x /usr/bin/chromium
    fi &&
    "$AGENT_BROWSER_EXECUTABLE_PATH" --version >/tmp/agent-browser-version.log 2>&1 &&
    agent-browser open "http://127.0.0.1:${OPENCODE_PORT}/health" >/tmp/agent-browser-open.log 2>&1 &&
    agent-browser pdf /tmp/example.pdf >/tmp/agent-browser-pdf.log 2>&1 &&
    test -s /tmp/example.pdf
  '
  [ "$status" -eq 0 ]
}

@test "compose stack forwards cors flag and strips empty auth username env" {
  prepare_test_stack
  export OPENCODE_CORS="https://example.com"
  export OPENCODE_SERVER_USERNAME=""

  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    tr "\0" " " < /proc/1/cmdline | grep -F -- "--cors https://example.com"
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^OPENCODE_SERVER_USERNAME="; then
      echo "OPENCODE_SERVER_USERNAME leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]
}

@test "compose stack forwards Dokploy CLI environment variables" {
  prepare_test_stack
  export DOKPLOY_URL="https://dokploy.example.test"
  export DOKPLOY_API_KEY="dokploy-test-key"
  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    test "$DOKPLOY_URL" = "https://dokploy.example.test" &&
    test "$DOKPLOY_API_KEY" = "dokploy-test-key"
  '
  [ "$status" -eq 0 ]
}

@test "compose stack applies default git identity config without exporting reserved git env vars" {
  prepare_test_stack
  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_NAME="; then
      echo "GIT_AUTHOR_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_EMAIL="; then
      echo "GIT_AUTHOR_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_NAME="; then
      echo "GIT_COMMITTER_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_EMAIL="; then
      echo "GIT_COMMITTER_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test -s /home/opencode/.gitmessage'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get user.name)" = "Oh-MyOpenAgent"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get user.email)" = "noreply@ohmyopencode.ai"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get author.name >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get author.email >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get committer.name >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc '! git config --global --get committer.email >/dev/null 2>&1'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get commit.template)" = "/home/opencode/.gitmessage"'
  [ "$status" -eq 0 ]
}

@test "compose stack applies explicit git identity overrides without exporting reserved git env vars" {
  prepare_test_stack
  export GIT_AUTHOR_NAME="Override Author"
  export GIT_AUTHOR_EMAIL="override-author@example.test"
  export GIT_COMMITTER_NAME="Override Committer"
  export GIT_COMMITTER_EMAIL="override-committer@example.test"
  start_test_stack

  run compose_ci exec -T opencode sh -lc '
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_NAME="; then
      echo "GIT_AUTHOR_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_AUTHOR_EMAIL="; then
      echo "GIT_AUTHOR_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_NAME="; then
      echo "GIT_COMMITTER_NAME leaked into runtime environment" >&2
      exit 1
    fi
    if tr "\0" "\n" < /proc/1/environ | grep -q "^GIT_COMMITTER_EMAIL="; then
      echo "GIT_COMMITTER_EMAIL leaked into runtime environment" >&2
      exit 1
    fi
  '
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get author.name)" = "Override Author"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get author.email)" = "override-author@example.test"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get committer.name)" = "Override Committer"'
  [ "$status" -eq 0 ]

  run compose_ci exec -T -u opencode opencode sh -lc 'test "$(git config --global --get committer.email)" = "override-committer@example.test"'
  [ "$status" -eq 0 ]
}
