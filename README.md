# opencode-docker

`opencode-docker` is a Docker Compose stack for [OpenCode](https://github.com/opencode-ai/opencode) with [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) pre-configured for Z.AI Coding Plan (GLM-5). Built for practical day-to-day use with strong host separation, reproducible tooling, and persistent configuration.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/) with [Docker Compose plugin](https://docs.docker.com/compose/)
- [Task](https://taskfile.dev/) for the documented local workflows
- Network access for image pulls and Z.AI API calls
- A valid Z.AI Coding Plan API key

## Included tools

- AI coding assistant:
  - [OpenCode](https://github.com/opencode-ai/opencode)
  - [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) with GLM-5 model mappings for all agent roles

- Platform tools:
  - [GitHub CLI (`gh`)](https://cli.github.com/manual/)
  - [GitLab CLI (`glab`)](https://docs.gitlab.com/cli/)
  - [atlcli](https://atlcli.sh/)

- Programming languages/runtimes:
  - [Python](https://www.python.org/) (pyenv)
  - [Node.js](https://nodejs.org/) (nvm, JavaScript/TypeScript)
  - [Go](https://go.dev/)
  - [Rust](https://www.rust-lang.org/)
  - [PHP 8.4](https://www.php.net/)
  - [Bun](https://bun.sh/)
  - Optional (build args): Java Temurin 21, Ruby 3.3, Swift 6.0, Elixir/OTP 27

- Developer tooling:
  - `docker` CLI with Compose plugin, `golangci-lint`, `yq`, `jq`, `git`, `curl`

## Security boundaries

- The container runs non-root via `gosu`.
- Runtime state is isolated in `./data/`.
- By default, no Docker socket or host config mounts (`~/.ssh`, `~/.gitconfig`) are exposed.
- Default port binding is `127.0.0.1` (localhost only).

> [!WARNING]
> Setting `OPENCODE_BIND_ADDRESS=0.0.0.0` exposes the port on all interfaces. Always set `OPENCODE_SERVER_PASSWORD` when doing this.

Docker daemon access is available only through the explicit Docker override documented below. Mounting the Docker socket lets OpenCode control the host Docker daemon and should only be used for trusted local development.

## Quick start

Required API keys:

- `ZHIPU_API_KEY` for the default GLM-5 model mapping
- `GEMINI_API_KEY` for the configured `multimodal-looker` agent using Gemini vision

Get the required keys:

### Z.AI

1. Open the [Z.AI Open Platform API key page](https://z.ai/manage-apikey/apikey-list)
2. Sign in or create an account
3. Create a new API key
4. Copy the generated key into `.env` as `ZHIPU_API_KEY`

### Google AI Studio

1. Open [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API Key**
4. Copy the generated key into `.env` as `GEMINI_API_KEY`

```bash
# 1. Clone the repository
git clone https://github.com/data219/opencode-docker.git
cd opencode-docker

# 2. Copy environment file and set your API key
cp .env.example .env
# Edit .env — set ZHIPU_API_KEY and GEMINI_API_KEY

# 3. Build and start
task build
task up

# 4. Open in browser
open http://localhost:4000
```

For CLI/TUI access, exec into the running container:

```bash
task opencode -- --help
```

All OpenCode state, skills, workspace content, and tool auth/config created in the container persist in `${OPENCODE_HOME_DIR:-./data/home}` because the full `/home/opencode` tree is bind-mounted.

## Daily tasks

Use the small `Taskfile.yml` for the normal local entrypoints:

| Task | Purpose |
| ---- | ------- |
| `task config` | Render effective Compose config |
| `task build` | Build the image with BuildKit |
| `task up` | Start the stack in the background |
| `task logs` | Follow the `opencode` service logs |
| `task shell` | Open a bash shell in the running container |
| `task opencode -- ...` | Run `opencode` inside the running container |
| `task test` | Run all Bats suites |

### Docker stack control

Use the Docker override only when you want OpenCode to start and test other Docker Compose stacks through the host Docker daemon:

```bash
docker compose -f docker-compose.yml -f docker-compose.docker.yml up -d
docker compose exec opencode docker version
docker compose exec opencode docker compose version
```

This keeps the default stack isolated while making Docker access a deliberate opt-in. Treat this mode as trusted-local only: Docker socket access can create privileged containers and mount host paths.

## Optional stack features

Use these only when you want to activate additional tooling beyond the default OpenCode web setup.

### CLI authentication

Authenticate the bundled CLIs if you want to use them inside the container.

### GitHub CLI (`gh`)

- Env-based auth: `GH_TOKEN` or `GITHUB_TOKEN`
- Interactive auth:

```bash
docker compose exec opencode gh auth login
```

### GitLab CLI (`glab`)

- Env-based auth: `GLAB_TOKEN` or `GITLAB_TOKEN`
- Interactive auth:

```bash
docker compose exec opencode glab auth login
```

### Atlassian CLI (`atlcli`)

- Env-based auth: `ATLCLI_API_TOKEN`
- Optional profile defaults: `ATLCLI_EMAIL`, `ATLCLI_SITE`, `ATLCLI_BASE_URL`
- Interactive auth:

```bash
docker compose exec opencode atlcli auth login --site https://your-company.atlassian.net
```

### Included skills

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

## Optional default customization

Use these variables only when the defaults do not fit your setup.

### Core runtime variables

**All env vars are optional except `ZHIPU_API_KEY` and `GEMINI_API_KEY`.**

| Variable             | Default   | What it configures                                                                                  |
| -------------------- | --------- | --------------------------------------------------------------------------------------------------- |
| `ZHIPU_API_KEY`      | *(required)* | Z.AI Coding Plan API key for GLM-5 models                                                       |
| `GEMINI_API_KEY`     | *(required)* | Google AI Studio API key for Gemini vision model used by the configured multimodal agent        |
| `OPENCODE_MODE`      | `web`     | Server mode: `web` (browser UI) or `serve` (API endpoint)                                          |
| `OPENCODE_PORT`      | `4000`    | Server port inside the container (1024–65535)                                                       |
| `OPENCODE_PRINT_LOGS` | `false`  | Maps to `opencode --print-logs` and streams OpenCode logs to container stderr                       |
| `OPENCODE_LOG_LEVEL` | *(empty)* | Maps to `opencode --log-level` with `DEBUG`, `INFO`, `WARN`, or `ERROR`                            |
| `OPENCODE_CORS` | *(empty)* | Maps to `opencode --cors` for one additional allowed origin; omitted entirely when empty             |
| `OPENCODE_SERVER_USERNAME` | OpenCode default (`opencode`) | Optional basic auth username; empty values are not forwarded            |
| `OPENCODE_SERVER_PASSWORD` | *(empty)* | Basic auth password. If empty, no auth is enforced — restrict via `OPENCODE_BIND_ADDRESS`       |
| `OPENCODE_BIND_ADDRESS` | `127.0.0.1` | **Host-level only.** Which interface Docker listens on. Never passed into the container.       |
| `FORCE_SKILL_SYNC`   | `false`   | `true` resets all skills to bootstrap defaults on startup; `false` preserves user modifications    |
| `GH_TOKEN`/`GITHUB_TOKEN` | *(empty)* | Token auth for `gh`. Alternative to interactive `gh auth login`. |
| `GLAB_TOKEN`/`GITLAB_TOKEN` | *(empty)* | Token auth for `glab`. Alternative to interactive `glab auth login`. |
| `GIT_AUTHOR_NAME` | `Oh-MyOpenAgent` | Startup default for git `author.name` (written to git config; not exported as runtime `GIT_*`). |
| `GIT_AUTHOR_EMAIL` | `noreply@ohmyopencode.ai` | Startup default for git `author.email` (written to git config; not exported as runtime `GIT_*`). |
| `GIT_COMMITTER_NAME` | `Oh-MyOpenAgent` | Startup default for git `committer.name` (written to git config; not exported as runtime `GIT_*`). |
| `GIT_COMMITTER_EMAIL` | `noreply@ohmyopencode.ai` | Startup default for git `committer.email` (written to git config; not exported as runtime `GIT_*`). |
| `ATLCLI_API_TOKEN` | *(empty)* | Token auth for `atlcli`. |
| `ATLCLI_EMAIL` | *(empty)* | Default Atlassian account email for `atlcli` auth flows. |
| `ATLCLI_SITE` | *(empty)* | Default Atlassian cloud site for `atlcli` auth flows. |
| `ATLCLI_BASE_URL` | *(empty)* | Base URL override for self-hosted/data-center Atlassian endpoints in `atlcli`. |

### Bind mount override

This variable controls the single Docker Compose host mount. If unset, it defaults to `./data/home`.

| Variable | Default | What it configures |
| -------- | ------- | ------------------ |
| `OPENCODE_HOME_DIR` | `./data/home` | Host path mounted to `/home/opencode` |

The mounted path persists the full `/home/opencode` tree, including OpenCode config/state, skills, workspace content, and CLI auth/config. All directories are created automatically on first start.

### Host-level vs container-level binding

`OPENCODE_BIND_ADDRESS` controls which host interface Docker exposes. The container always binds `0.0.0.0` internally (required for port forwarding).

- `127.0.0.1` (default) — localhost only, safe for development
- `0.0.0.0` — all interfaces, **must** set `OPENCODE_SERVER_PASSWORD`

> **Note:** Args after the mode are silently ignored. Use environment variables for all OpenCode configuration.

Logging example:

```bash
OPENCODE_PRINT_LOGS=true
OPENCODE_LOG_LEVEL=DEBUG
task up
task logs
```

CORS example:

```bash
OPENCODE_CORS=https://opencode.example.com
task up
```
## Config management

Managed config files (`.managed` suffix in the image defaults) are overwritten when the config version increases. Non-managed files are only seeded if they don't exist — user edits are always preserved.

When you pull a new image with updated defaults, the entrypoint detects version mismatches and warns you. No user files are silently overwritten.

## Upgrading

```bash
git pull
task build
task up
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

## CI / QA

GitHub Actions QA is split into two workflows:

- `Build` runs a direct `docker build -t opencode-docker:test .` validation of the Dockerfile without `docker compose`.
- `Testing` runs after a successful `Build` workflow and executes `task test-unit`, `task test-lint`, and `task test-integration`.

`task test-integration` boots the Docker Compose stack for real, waits for container health, and verifies the runtime OpenCode/OmO setup inside the container.

## License

MIT
