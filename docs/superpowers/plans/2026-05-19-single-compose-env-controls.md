# Single Compose Env Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current three Compose-file workflow with one `docker-compose.yml` controlled by `.env` and Compose profiles.

**Architecture:** Keep `opencode` as the only main service and move optional Cloudflare tunnel services into the same Compose file with `tunnel-quick` and `tunnel-managed` profiles. Docker socket access stays on the `opencode` service and is enabled with an environment-substituted bind path because Compose profiles cannot toggle individual service fields.

**Tech Stack:** Docker Compose, Taskfile, Bash, Bats, Markdown.

---

## File Structure

- Modify: `docker-compose.yml`
  - Owns the full stack: `opencode`, `cloudflared`, and `cloudflared-managed`.
  - Adds the inert Docker socket bind default through `${OPENCODE_DOCKER_SOCKET_BIND:-./.docker-socket-disabled}`.
- Delete: `docker-compose.docker.yml`
  - Behavior moves into `docker-compose.yml`.
- Delete: `docker-compose.tunnel.yml`
  - Tunnel services move into `docker-compose.yml`.
- Modify: `Taskfile.yml`
  - Removes overlay-file command assembly.
  - Keeps tunnel convenience tasks by setting `COMPOSE_PROFILES` inline.
- Modify: `.env.example`
  - Adds commented ready-to-uncomment blocks for Docker socket and tunnel activation.
  - Removes stale `-f docker-compose.*.yml` examples.
- Modify: `scripts/migrate-env.sh`
  - Adds a migration helper that preserves active old Docker socket intent by adding `OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock`.
- Modify: `tests/unit/test_migrate_env.bats`
  - Adds Docker socket migration coverage.
- Modify: `tests/lint/test_compose.bats`
  - Replaces overlay-file assertions with profile/env assertions against the single Compose file.
- Modify: `README.md`
  - Documents one Compose file and `.env`-driven optional behavior.

## Task 1: Add Single-File Compose Behavior

**Files:**
- Modify: `docker-compose.yml`
- Test: `tests/lint/test_compose.bats`

- [ ] **Step 1: Write failing Compose lint tests**

Replace `tests/lint/test_compose.bats` with:

```bash
@test "docker-compose.yml exists" {
  [ -f docker-compose.yml ]
}

@test "docker-compose.yml validates with docker compose config" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  OCD_ZHIPU_API_KEY=test \
    GIT_AUTHOR_NAME= \
    GIT_AUTHOR_EMAIL= \
    GIT_COMMITTER_NAME= \
    GIT_COMMITTER_EMAIL= \
    docker compose config > /dev/null
}

@test "docker-compose.yml validates quick tunnel profile" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  OCD_ZHIPU_API_KEY=test \
    COMPOSE_PROFILES=tunnel-quick \
    docker compose config > /dev/null
}

@test "docker-compose.yml validates managed tunnel profile" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  OCD_ZHIPU_API_KEY=test \
    CF_TUNNEL_TOKEN=test \
    COMPOSE_PROFILES=tunnel-managed \
    docker compose config > /dev/null
}

@test "quick tunnel profile does not require CF_TUNNEL_TOKEN" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  OCD_ZHIPU_API_KEY=test \
    COMPOSE_PROFILES=tunnel-quick \
    docker compose config > /dev/null
}

@test "docker socket env renders host docker socket mount" {
  docker compose version > /dev/null 2>&1 || skip "docker compose not available"
  run env \
    OCD_ZHIPU_API_KEY=test \
    OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock \
    docker compose config

  [ "$status" -eq 0 ]
  [[ "$output" == *"source: /var/run/docker.sock"* ]]
  [[ "$output" == *"target: /var/run/docker.sock"* ]]
  [[ "$output" == *"OPENCODE_DOCKER_SOCKET: /var/run/docker.sock"* ]]
  [[ "$output" == *"DOCKER_HOST: unix:///var/run/docker.sock"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
tests/bats-core/bin/bats --recursive --timing tests/lint/test_compose.bats
```

Expected: FAIL because `docker-compose.yml` does not yet contain the tunnel services or Docker socket bind.

- [ ] **Step 3: Update `docker-compose.yml`**

Edit the `opencode` service volumes and environment to include Docker socket controls:

```yaml
    volumes:
      - ${OPENCODE_HOME_DIR:-./data/home}:/home/opencode
      - ${OPENCODE_DOCKER_SOCKET_BIND:-./.docker-socket-disabled}:/var/run/docker.sock
    environment:
      # WARNING: Container binds 0.0.0.0 internally (required for port forwarding).
      # Set OPENCODE_BIND_ADDRESS (host-level) and OPENCODE_SERVER_PASSWORD to restrict access.
      - OPENCODE_MODE=${OPENCODE_MODE:-web}
      - OPENCODE_PORT=${OPENCODE_PORT:-4000}
      - OPENCODE_SERVER_USERNAME=${OPENCODE_SERVER_USERNAME:-}
      - OPENCODE_SERVER_PASSWORD=${OPENCODE_SERVER_PASSWORD:-}
      - OPENCODE_CORS=${OPENCODE_CORS:-}
      - OPENCODE_PRINT_LOGS=${OPENCODE_PRINT_LOGS:-false}
      - OPENCODE_LOG_LEVEL=${OPENCODE_LOG_LEVEL:-}
      - FORCE_SKILL_SYNC=${FORCE_SKILL_SYNC:-false}
      - OPENCHAMBER_ENABLED=${OPENCHAMBER_ENABLED:-false}
      - OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-4020}
      - OPENCHAMBER_UI_PASSWORD=${OPENCHAMBER_UI_PASSWORD:-}
      - OPENCODE_DOCKER_SOCKET=${OPENCODE_DOCKER_SOCKET_BIND:+/var/run/docker.sock}
      - DOCKER_HOST=${OPENCODE_DOCKER_SOCKET_BIND:+unix:///var/run/docker.sock}
      - OCD_ZHIPU_API_KEY=${OCD_ZHIPU_API_KEY:?OCD_ZHIPU_API_KEY is required}
      - OCD_GEMINI_API_KEY=${OCD_GEMINI_API_KEY:-}
      - GH_TOKEN=${GH_TOKEN:-}
      - GITHUB_TOKEN=${GITHUB_TOKEN:-}
      - GLAB_TOKEN=${GLAB_TOKEN:-}
      - GITLAB_TOKEN=${GITLAB_TOKEN:-}
      - CNTB_OAUTH2_CLIENT_ID=${CNTB_OAUTH2_CLIENT_ID:-}
      - CNTB_OAUTH2_CLIENT_SECRET=${CNTB_OAUTH2_CLIENT_SECRET:-}
      - CNTB_OAUTH2_USER=${CNTB_OAUTH2_USER:-}
      - CNTB_OAUTH2_PASSWORD=${CNTB_OAUTH2_PASSWORD:-}
      - OPENCODE_GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME:-}
      - OPENCODE_GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL:-}
      - OPENCODE_GIT_COMMITTER_NAME=${GIT_COMMITTER_NAME:-}
      - OPENCODE_GIT_COMMITTER_EMAIL=${GIT_COMMITTER_EMAIL:-}
      - ATLCLI_API_TOKEN=${ATLCLI_API_TOKEN:-}
      - ATLCLI_EMAIL=${ATLCLI_EMAIL:-}
      - ATLCLI_SITE=${ATLCLI_SITE:-}
      - ATLCLI_BASE_URL=${ATLCLI_BASE_URL:-}
```

Append the tunnel services under `services:`:

```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command:
      [
        "tunnel",
        "--url",
        "http://${CF_TUNNEL_TARGET_HOST:-opencode}:${CF_TUNNEL_TARGET_PORT:-${OPENCODE_PORT:-4000}}"
      ]
    depends_on:
      opencode:
        condition: service_healthy
    profiles:
      - tunnel-quick

  cloudflared-managed:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-managed
    restart: unless-stopped
    command: ["tunnel", "--no-autoupdate", "run"]
    environment:
      - TUNNEL_TOKEN=${CF_TUNNEL_TOKEN:-}
    depends_on:
      opencode:
        condition: service_healthy
    profiles:
      - tunnel-managed
```

- [ ] **Step 4: Run Compose lint tests**

Run:

```bash
tests/bats-core/bin/bats --recursive --timing tests/lint/test_compose.bats
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml tests/lint/test_compose.bats
git commit -m "feat: consolidate compose profile controls"
```

## Task 2: Update Taskfile and Env Migration

**Files:**
- Modify: `Taskfile.yml`
- Modify: `.env.example`
- Modify: `scripts/migrate-env.sh`
- Modify: `tests/unit/test_migrate_env.bats`

- [ ] **Step 1: Add failing migration tests**

Append these tests to `tests/unit/test_migrate_env.bats`:

```bash
@test "migrate-env adds docker socket bind when legacy socket is active" {
  cat > "$TEST_ENV_FILE" <<'EOF'
OPENCODE_DOCKER_SOCKET=/var/run/docker.sock
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
# OPENCODE_DOCKER_SOCKET_BIND=./.docker-socket-disabled
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^OPENCODE_DOCKER_SOCKET=/var/run/docker.sock$'
  assert_env_file_contains "$TEST_ENV_FILE" '^OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock$'
}

@test "migrate-env keeps inactive docker socket examples commented" {
  cat > "$TEST_ENV_FILE" <<'EOF'
OCD_ZHIPU_API_KEY=already-set
EOF

  cat > "$TEST_EXAMPLE_FILE" <<'EOF'
# OPENCODE_DOCKER_SOCKET_BIND=./.docker-socket-disabled
EOF

  run scripts/migrate-env.sh "$TEST_ENV_FILE" "$TEST_EXAMPLE_FILE"

  assert_success
  assert_env_file_contains "$TEST_ENV_FILE" '^# OPENCODE_DOCKER_SOCKET_BIND=./.docker-socket-disabled$'
  refute_env_file_contains "$TEST_ENV_FILE" '^OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock$'
}
```

- [ ] **Step 2: Run migration tests to verify failure**

Run:

```bash
tests/bats-core/bin/bats --recursive --timing tests/unit/test_migrate_env.bats
```

Expected: FAIL because `scripts/migrate-env.sh` does not yet add `OPENCODE_DOCKER_SOCKET_BIND`.

- [ ] **Step 3: Update `scripts/migrate-env.sh`**

Add this function after `append_missing_from_example()`:

```bash
preserve_active_docker_socket_bind() {
  local env_file="$1"

  if active_env_var_exists "$env_file" "OPENCODE_DOCKER_SOCKET_BIND"; then
    return
  fi

  if active_env_var_value "$env_file" "OPENCODE_DOCKER_SOCKET" | grep -Eq '^/var/run/docker\.sock$'; then
    printf '%s\n' 'OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock' >> "$env_file"
  fi
}
```

Call it before appending missing examples:

```bash
for rename in "${RENAMES[@]}"; do
  old_name="${rename%%:*}"
  new_name="${rename#*:}"
  rename_env_var "$ENV_FILE" "$old_name" "$new_name"
done

preserve_active_docker_socket_bind "$ENV_FILE"
append_missing_from_example "$ENV_FILE" "$EXAMPLE_FILE"
```

- [ ] **Step 4: Update `.env.example` optional controls**

Replace the Docker host delegation block with:

```env
# Optional: Docker host delegation.
# Uncomment this block when OpenCode needs to run Docker commands against the
# host daemon. Docker socket access is effectively host-root equivalent.
# Compose derives the container OPENCODE_DOCKER_SOCKET and DOCKER_HOST values
# when this bind is set.
# OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock
```

Replace the Cloudflare tunnel command examples with:

```env
# --- Cloudflare Tunnel (optional remote access) ---
# Expose OpenCode over the internet without opening ports.
#
# Quick tunnel (no account needed, random URL):
#   COMPOSE_PROFILES=tunnel-quick
#   Check URL: docker compose logs cloudflared
#
# Managed tunnel (stable domain, Cloudflare account):
#   COMPOSE_PROFILES=tunnel-managed
#   CF_TUNNEL_TOKEN=...
#   Create a tunnel at https://one.dash.cloudflare.com/
#
# WARNING: Tunnel URLs are publicly accessible.
#   Set OPENCODE_SERVER_PASSWORD before enabling the tunnel!

# Optional: enable one Compose profile.
# Leave empty for the local-only base stack.
# COMPOSE_PROFILES=

# Cloudflare tunnel token (required for managed mode).
# CF_TUNNEL_TOKEN=

# Target host inside Docker (default: opencode container name).
# CF_TUNNEL_TARGET_HOST=opencode

# Target port inside Docker (default: 4000, the OpenCode port).
# CF_TUNNEL_TARGET_PORT=4000
```

- [ ] **Step 5: Simplify `Taskfile.yml`**

Replace the `vars:` block with:

```yaml
vars:
  BATS: tests/bats-core/bin/bats
  BATS_ARGS: --recursive --timing
  DOCKER_COMPOSE: docker compose -f docker-compose.yml
```

Replace tunnel tasks with:

```yaml
  tunnel-quick:
    desc: Start Cloudflare quick tunnel (random URL, no account)
    cmds:
      - COMPOSE_PROFILES=tunnel-quick {{.DOCKER_COMPOSE}} up -d

  tunnel-managed:
    desc: Start Cloudflare managed tunnel (stable domain, requires CF_TUNNEL_TOKEN)
    cmds:
      - COMPOSE_PROFILES=tunnel-managed {{.DOCKER_COMPOSE}} up -d

  tunnel-down:
    desc: Stop Cloudflare tunnel services without affecting the main stack
    cmds:
      - "{{.DOCKER_COMPOSE}} stop cloudflared cloudflared-managed || true"
      - "{{.DOCKER_COMPOSE}} rm -f cloudflared cloudflared-managed || true"
```

- [ ] **Step 6: Run targeted tests**

Run:

```bash
tests/bats-core/bin/bats --recursive --timing tests/unit/test_migrate_env.bats
tests/bats-core/bin/bats --recursive --timing tests/lint/test_compose.bats
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Taskfile.yml .env.example scripts/migrate-env.sh tests/unit/test_migrate_env.bats
git commit -m "feat: migrate env controls for single compose"
```

## Task 3: Update README Documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update security wording**

Replace references to the Docker override with Docker socket mode:

```markdown
- Docker socket mode mounts `/var/run/docker.sock`, which gives access to the host Docker daemon.
- Cloudflare tunnel profiles expose the service over the internet. Set `OPENCODE_SERVER_PASSWORD` first.
```

- [ ] **Step 2: Update the development workflow Docker socket section**

Replace the `### Docker socket override` section with:

````markdown
### Docker socket mode

Enable Docker socket mode when OpenCode needs to run Docker commands against the host daemon.

In `.env`, uncomment:

```env
OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock
```

Compose derives the container `OPENCODE_DOCKER_SOCKET` and `DOCKER_HOST` values from the bind setting. `OPENCODE_DOCKER_SOCKET` uses the container mount path `/var/run/docker.sock`, even when the host bind source uses another socket path.

Then start the stack and verify Docker access:

```bash
task up
docker compose exec opencode docker version
```

Docker socket access is effectively host-root equivalent. Use it only for trusted local workflows.
````

- [ ] **Step 3: Update the Cloudflare tunnels section**

Replace the `### Cloudflare tunnels` section with:

````markdown
### Cloudflare tunnels

Tunnel services live in the main Compose file and are enabled through `COMPOSE_PROFILES`.

Quick tunnel:

```env
COMPOSE_PROFILES=tunnel-quick
```

```bash
task up
docker compose logs cloudflared
```

Managed tunnel:

```env
COMPOSE_PROFILES=tunnel-managed
CF_TUNNEL_TOKEN=...
```

```bash
task up
docker compose logs cloudflared-managed
```

Use `task tunnel-down` to stop tunnel services without stopping OpenCode. Enable only one tunnel profile for normal use.
````

- [ ] **Step 4: Remove stale overlay references**

Run:

```bash
rg -n "docker-compose\\.docker|docker-compose\\.tunnel|-f docker-compose" README.md
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document env-driven compose controls"
```

## Task 4: Remove Overlay Files and Verify End-to-End

**Files:**
- Delete: `docker-compose.docker.yml`
- Delete: `docker-compose.tunnel.yml`
- Verify: `Taskfile.yml`, `.env.example`, `README.md`, `tests/lint/test_compose.bats`

- [ ] **Step 1: Delete obsolete Compose overlays**

Run:

```bash
rm -f docker-compose.docker.yml docker-compose.tunnel.yml
```

- [ ] **Step 2: Check for stale references**

Run:

```bash
rg -n "docker-compose\\.docker|docker-compose\\.tunnel|-f docker-compose\\.(docker|tunnel)" README.md Taskfile.yml .env.example tests scripts docker-compose.yml renovate.json .github 2>/dev/null
```

Expected: no output.

- [ ] **Step 3: Render base Compose config**

Run:

```bash
OCD_ZHIPU_API_KEY=dummy OCD_GEMINI_API_KEY=dummy docker compose config --quiet
```

Expected: exit 0.

- [ ] **Step 4: Render quick tunnel config**

Run:

```bash
OCD_ZHIPU_API_KEY=dummy OCD_GEMINI_API_KEY=dummy COMPOSE_PROFILES=tunnel-quick docker compose config --quiet
```

Expected: exit 0.

- [ ] **Step 5: Render managed tunnel config**

Run:

```bash
OCD_ZHIPU_API_KEY=dummy OCD_GEMINI_API_KEY=dummy CF_TUNNEL_TOKEN=dummy COMPOSE_PROFILES=tunnel-managed docker compose config --quiet
```

Expected: exit 0.

- [ ] **Step 6: Run the focused Bats suites**

Run:

```bash
tests/bats-core/bin/bats --recursive --timing tests/unit/test_migrate_env.bats
tests/bats-core/bin/bats --recursive --timing tests/lint/test_compose.bats
```

Expected: PASS.

- [ ] **Step 7: Run full local verification**

Run:

```bash
task test-unit
task test-lint
```

Expected: PASS.

Run integration only if Docker build time and local resources allow:

```bash
task test-integration
```

Expected: PASS. If skipped, state clearly that only unit and lint suites ran.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete compose overlays"
```

## Self-Review

- Spec coverage: The plan covers single-file Compose, tunnel profiles, Docker socket env controls, `.env.example`, migration behavior, Taskfile changes, README updates, overlay deletion, and verification.
- Placeholder scan: No placeholder markers or deferred implementation notes remain.
- Type and name consistency: Profile names are `tunnel-quick` and `tunnel-managed`; Docker socket variables are `OPENCODE_DOCKER_SOCKET_BIND`, `OPENCODE_DOCKER_SOCKET`, and `DOCKER_HOST`.
