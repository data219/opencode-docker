# opencode-docker

`opencode-docker` is a Docker Compose stack for [OpenCode](https://github.com/opencode-ai/opencode) with [Oh-My-OpenAgent](https://github.com/nimbleflux/oh-my-opencode) pre-configured for Z.AI Coding Plan (GLM-5). Built for practical day-to-day use with strong host separation, reproducible tooling, and persistent configuration.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/) with [Docker Compose plugin](https://docs.docker.com/compose/)
- Network access for image pulls and Z.AI API calls
- A valid Z.AI Coding Plan API key

## Included tools

- AI coding assistant:
  - [OpenCode](https://github.com/opencode-ai/opencode)
  - [Oh-My-OpenAgent](https://github.com/nimbleflux/oh-my-opencode) with GLM-5 model mappings for all agent roles

- Platform tools:
  - [GitHub CLI (`gh`)](https://cli.github.com/manual/)

- Programming languages/runtimes:
  - [Python](https://www.python.org/) (pyenv)
  - [Node.js](https://nodejs.org/) (nvm, JavaScript/TypeScript)
  - [Go](https://go.dev/)
  - [Rust](https://www.rust-lang.org/)
  - [PHP 8.4](https://www.php.net/)
  - [Bun](https://bun.sh/)
  - Optional (build args): Java Temurin 21, Ruby 3.3, Swift 6.0, Elixir/OTP 27

- Developer tooling:
  - `golangci-lint`, `yq`, `jq`, `git`, `curl`

## Security boundaries

- The container runs non-root via `gosu`.
- Runtime state is isolated in `./data/`.
- No Docker socket or host config mounts (`~/.ssh`, `~/.gitconfig`) are exposed.
- Default port binding is `127.0.0.1` (localhost only).

> [!WARNING]
> Setting `OPENCODE_BIND_ADDRESS=0.0.0.0` exposes the port on all interfaces. Always set `OPENCODE_SERVER_PASSWORD` when doing this.

## Quick start

```bash
# 1. Clone the repository
git clone https://github.com/data219/opencode-docker.git
cd opencode-docker

# 2. Copy environment file and set your API key
cp .env.example .env
# Edit .env — set ZHIPU_API_KEY (required)

# 3. Build and start
DOCKER_BUILDKIT=1 docker compose up -d

# 4. Open in browser
open http://localhost:4000
```

For CLI/TUI access, exec into the running container:

```bash
docker exec -it opencode -- opencode
```

## Configuration

**All env vars are optional except `ZHIPU_API_KEY`.**

### Core runtime variables

| Variable             | Default   | What it configures                                                                                  |
| -------------------- | --------- | --------------------------------------------------------------------------------------------------- |
| `ZHIPU_API_KEY`      | *(required)* | Z.AI Coding Plan API key for GLM-5 models                                                       |
| `OPENCODE_MODE`      | `web`     | Server mode: `web` (browser UI) or `serve` (API endpoint)                                          |
| `OPENCODE_PORT`      | `4000`    | Server port inside the container (1024–65535)                                                       |
| `OPENCODE_SERVER_USERNAME` | `opencode` | Basic auth username (set both username and password, or neither)                              |
| `OPENCODE_SERVER_PASSWORD` | *(empty)* | Basic auth password. If empty, no auth is enforced — restrict via `OPENCODE_BIND_ADDRESS`       |
| `OPENCODE_BIND_ADDRESS` | `127.0.0.1` | **Host-level only.** Which interface Docker listens on. Never passed into the container.       |
| `FORCE_SKILL_SYNC`   | `false`   | `true` resets all skills to bootstrap defaults on startup; `false` preserves user modifications    |

### Host-level vs container-level binding

`OPENCODE_BIND_ADDRESS` controls which host interface Docker exposes. The container always binds `0.0.0.0` internally (required for port forwarding).

- `127.0.0.1` (default) — localhost only, safe for development
- `0.0.0.0` — all interfaces, **must** set `OPENCODE_SERVER_PASSWORD`

> **Note:** Args after the mode are silently ignored. Use environment variables for all OpenCode configuration.

## Bind mount structure

| Host Path            | Container Path                    | Description                                              |
| -------------------- | --------------------------------- | -------------------------------------------------------- |
| `./data/config/`     | `/home/opencode/.config/opencode` | OpenCode + OmO config (seeded on first run, version-tracked) |
| `./data/share/`      | `/home/opencode/.local/share/opencode` | OpenCode persistent data                            |
| `./data/state/`      | `/home/opencode/.local/state/opencode`  | OpenCode state                                     |
| `./data/workspace/`  | `/home/opencode/workspace`        | Project workspace (writable)                            |
| `./data/skills/`     | `/home/opencode/.agents/skills`   | Skills (synced from bootstrap on start)                 |

All directories are created automatically on first start.

## Config management

Managed config files (`.managed` suffix in the image defaults) are overwritten when the config version increases. Non-managed files are only seeded if they don't exist — user edits are always preserved.

When you pull a new image with updated defaults, the entrypoint detects version mismatches and warns you. No user files are silently overwritten.

## Skills

`bootstrap/skills/` is vendored in-repo and synced into the runtime home on container start.

Included categories:

- **Platform skills**: `github`, `glab`, `atlcli`, `linear`
- **Code review**: `code-review-master`
- **Security**: `security-threat-model`, `secrets-management`, `skeptic`
- **CI/CD**: `deployment-pipeline-design`, `github-actions-templates`, `gitlab-ci-patterns`, `enterprise-readiness`
- **Architecture**: `error-handling-patterns`, `context7`
- **PHP**: `php`
- **Incident response**: `incident-response`

Set `FORCE_SKILL_SYNC=true` to reset all skills to bootstrap defaults.

## Upgrading

```bash
git pull
DOCKER_BUILDKIT=1 docker compose build
docker compose up -d
```

Managed configs are automatically re-seeded when the image ships a new config version. Your non-managed customizations are preserved.

### Rollback

```bash
docker compose down
DOCKER_BUILDKIT=1 docker compose build
docker compose up -d
```

## Contributing

Build instructions, testing, config seeding internals, and architectural decisions are documented in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
