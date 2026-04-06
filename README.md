# data219/opencode-docker

Docker container for [OpenCode](https://github.com/opencode-ai/opencode) with [Oh-My-OpenAgent (OmO)](https://github.com/nimbleflux/oh-my-opencode) pre-configured for Z.AI Coding Plan (GLM-5).

> **⚠️ Development-only container.** Not intended for production use.

## Upstream

Forked from [nimbleflux/opencode-docker](https://github.com/nimbleflux/opencode-docker). See [Upstream Sync](#upstream-sync) for how to merge upstream changes.

## Features

- **OpenCode** AI coding assistant running in `web` or `serve` mode
- **Oh-My-OpenAgent** with GLM-5 model for all agent roles (sisyphus, prometheus, metis, oracle, momus)
- **GLM-4.6v** for multimodal-looker agent
- **Multi-language development environment**: Python (pyenv), Node.js (nvm), Go, Rust, PHP 8.4, Bun
- **Optional languages** via build args: Java (Temurin 21), Ruby 3.3, Swift 6.0, Elixir/OTP 27
- **Developer tooling**: golangci-lint, Composer, gh CLI, yq
- **Custom skills** support via read-only bind mount at `/home/opencode/.agents/skills`
- **BuildKit cache mounts** for fast rebuilds
- **Config seeding**: defaults copied on first run, user edits persist
- **Config drift detection**: warns when image defaults change

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/data219/opencode-docker.git
cd opencode-docker

# 2. Copy environment file and set your API key
cp .env.example .env
# Edit .env — set ZHIPU_API_KEY (required)

# 3. Build and start (requires DOCKER_BUILDKIT=1)
DOCKER_BUILDKIT=1 docker compose up -d

# 4. Open in browser
open http://localhost:4000
```

For CLI/TUI access, exec into the running container:

```bash
docker exec -it opencode -- opencode
```

## Building

Requires Docker BuildKit:

```bash
DOCKER_BUILDKIT=1 docker compose build
```

### Optional Languages

To include additional language runtimes at build time, set build args in `.env` before building:

```bash
# In .env (set before building)
INSTALL_JAVA=true
INSTALL_RUBY=true
INSTALL_SWIFT=true
INSTALL_ELIXIR=true

# Then build
DOCKER_BUILDKIT=1 docker compose build
```

## Configuration

All configuration is done via environment variables in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `ZHIPU_API_KEY` | *(required)* | Z.AI Coding Plan API key |
| `OPENCODE_MODE` | `web` | Server mode: `web` or `serve` |
| `OPENCODE_PORT` | `4000` | Server port (1024–65535) |
| `OPENCODE_SERVER_USERNAME` | `opencode` | Basic auth username |
| `OPENCODE_SERVER_PASSWORD` | *(empty)* | Basic auth password |
| `OPENCODE_BIND_ADDRESS` | `127.0.0.1` | **Host-level port binding** (Docker Compose only — NOT passed into container) |
| `INSTALL_JAVA` | `false` | Build arg: install Java Temurin 21 |
| `INSTALL_RUBY` | `false` | Build arg: install Ruby 3.3 |
| `INSTALL_SWIFT` | `false` | Build arg: install Swift 6.0 |
| `INSTALL_ELIXIR` | `false` | Build arg: install Elixir + Erlang/OTP 27 |
| `OMO_VERSION` | `3.14.0` | Build arg: Oh-My-OpenAgent version |

> **Note:** Args after mode are silently ignored. Use environment variables for all OpenCode configuration.

### OPENCODE_BIND_ADDRESS (Host-Level Only)

`OPENCODE_BIND_ADDRESS` controls which host interface Docker listens on. It is **never passed into the container**. The container always binds `0.0.0.0` internally (required for host port forwarding to work).

- `127.0.0.1` (default) — localhost only, safe for development
- `0.0.0.0` — all interfaces, **MUST** set `OPENCODE_SERVER_PASSWORD`

## Custom Skills

Mount a local `skills/` directory containing skill folders. Each skill is a folder with a `SKILL.md` file:

```
skills/
└── my-skill/
    └── SKILL.md
```

The skills directory is mounted read-only (`:ro`) at `/home/opencode/.agents/skills` inside the container. OpenCode discovers skills from this path automatically.

## Bind Mount Structure

| Host Path | Container Path | Description |
|-----------|---------------|-------------|
| `./opencode-config/` | `/home/opencode/.config/opencode` | OpenCode + OmO config (seeded on first run) |
| `./opencode-data/` | `/home/opencode/.local/share/opencode` | OpenCode persistent data |
| `./opencode-state/` | `/home/opencode/.local/state/opencode` | OpenCode state |
| `./opencode-workspace/` | `/home/opencode/workspace` | Project workspace |
| `./skills/` | `/home/opencode/.agents/skills` | Custom skills (read-only) |

All bind mount directories are created automatically on first start. Config files are seeded from `/opt/opencode-defaults/` only when the target does not exist — user edits are never overwritten.

## Config Drift Detection

The image includes a config version marker (`.opencode-docker-config-version`). When you pull a new image with updated defaults, the entrypoint detects the version mismatch and prints a warning:

```
WARNING: Config version mismatch. Image defaults are v2 but your config is v1.
  Your config is NOT overwritten. To update manually:
    docker exec -it <container> -- cat /opt/opencode-defaults/opencode.json > /home/opencode/.config/opencode/opencode.json
  Then update the version marker to match.
```

## Security Notes

- **API Key**: `ZHIPU_API_KEY` is required and passed via environment variable. Never commit `.env` to version control.
- **Port Binding**: Default `OPENCODE_BIND_ADDRESS=127.0.0.1` restricts access to localhost. Setting `0.0.0.0` exposes the port on all interfaces — always set a password.
- **Container binds 0.0.0.0**: The container always binds all interfaces internally (required for Docker port forwarding). Host-level restriction is handled by `OPENCODE_BIND_ADDRESS`.
- **No `--password` in process list**: OpenCode reads `OPENCODE_SERVER_PASSWORD` natively from the environment.
- **Docker Secrets**: For production-like setups, consider using [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) instead of environment variables.

## Upstream Sync

To merge changes from [nimbleflux/opencode-docker](https://github.com/nimbleflux/opencode-docker):

```bash
git remote add upstream https://github.com/nimbleflux/opencode-docker.git
git fetch upstream
git merge upstream/main --no-edit
# Resolve conflicts and test
make test-all
```

## Rollback

```bash
# Revert to a previous image
docker compose down
docker tag opencode:latest opencode:backup
DOCKER_BUILDKIT=1 docker compose build
docker compose up -d
```

## Phase 2 (Future)

Phase 2 will be developed on a separate branch with Ubuntu 24.04 and the full codex-universal language/tool set including mise version manager, multi-stage build evaluation, and ARM64 support.

## Testing

```bash
# Run all tests
make test-all

# Individual suites
make test-unit          # Fast, no Docker required
make test-lint          # Structural assertions
make test-integration   # Requires Docker build (--jobs 1)
```

Requires `DOCKER_BUILDKIT=1` for integration tests.

## License

MIT
