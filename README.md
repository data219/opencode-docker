# opencode-docker

`opencode-docker` runs OpenCode and related agent tooling in Docker Compose. The goal is simple: keep the agent runtime, toolchains, config, and persisted home directory in one reproducible local environment instead of spreading them across the host.

- It exists for local OpenCode and Oh My OpenAgent sessions where the toolchain should be repeatable.
- Docker keeps the installed tools, runtime processes, port bindings, and container home separate from the host by default.
- Current support covers OpenCode web/serve mode, OpenChamber, Z.AI GLM defaults, Gemini vision for OmO visual tasks, bundled skills, Bats tests, and GitHub Actions checks.

## Quick start

### Prerequisites

- Docker Engine with the Docker Compose plugin
- [Task](https://taskfile.dev/) for the documented commands
- Network access for image pulls and model API calls
- A Z.AI Coding Plan API key for the GLM provider
- A Google AI Studio API key for the Gemini vision model used by OmO visual tasks

### Start the stack

```bash
git clone https://github.com/data219/opencode-docker.git
cd opencode-docker

cp .env.example .env
# Edit .env and set OCD_ZHIPU_API_KEY and OCD_GEMINI_API_KEY.

task build
task up
open http://localhost:4000
```

For CLI access inside the running container:

```bash
task opencode -- --help
task shell
```

Docker Compose mounts `${OPENCODE_HOME_DIR:-./data/home}` to `/home/opencode`, so OpenCode state, skills, CLI auth, and workspace files survive container restarts.

## Configuration

`OCD_ZHIPU_API_KEY` and `OCD_GEMINI_API_KEY` are required for the documented setup. Compose only enforces `OCD_ZHIPU_API_KEY`, but OmO visual tasks need the Gemini-backed vision model.

| Variable | Default | Purpose |
| --- | --- | --- |
| `OCD_ZHIPU_API_KEY` | required | Z.AI Coding Plan API key used by the default GLM provider. |
| `OCD_GEMINI_API_KEY` | required | Google AI Studio key for the Gemini vision model used by OmO visual tasks. |
| `OPENCODE_MODE` | `web` | OpenCode server mode: `web` or `serve`. |
| `OPENCODE_PORT` | `4000` | OpenCode port inside the container and on the host. |
| `OPENCODE_BIND_ADDRESS` | `127.0.0.1` | Host interface Docker publishes to. Use `0.0.0.0` only with auth. |
| `OPENCODE_SERVER_USERNAME` | OpenCode default | Optional basic-auth username. Empty values are not forwarded. |
| `OPENCODE_SERVER_PASSWORD` | empty | Optional basic-auth password. Set this before exposing ports beyond localhost. |
| `OPENCODE_CORS` | empty | Optional single CORS origin passed to OpenCode. |
| `OPENCODE_PRINT_LOGS` | `false` | Streams OpenCode logs to container stderr. |
| `OPENCODE_LOG_LEVEL` | empty | Optional `DEBUG`, `INFO`, `WARN`, or `ERROR`. |
| `OPENCODE_HOME_DIR` | `./data/home` | Host path mounted as `/home/opencode`. |
| `OPENCHAMBER_ENABLED` | `false` | Starts OpenChamber alongside OpenCode. |
| `OPENCHAMBER_PORT` | `4020` | OpenChamber port inside the container and on the host. |
| `OPENCHAMBER_UI_PASSWORD` | empty | Optional OpenChamber UI password. Set this for non-local exposure. |
| `FORCE_SKILL_SYNC` | `false` | Replaces bootstrapped skills with image defaults when set to `true`. |
| `GH_TOKEN` / `GITHUB_TOKEN` | empty | Non-interactive GitHub CLI auth. |
| `GLAB_TOKEN` / `GITLAB_TOKEN` | empty | Non-interactive GitLab CLI auth. |
| `CNTB_OAUTH2_*` | empty | Contabo CLI auth. Set all four OAuth2 variables together. |
| `ATLCLI_*` | empty | Atlassian CLI token and profile defaults. |

Run `task migrate-env` after pulling changes if your `.env` still uses old names such as `ZHIPU_API_KEY` or `GEMINI_API_KEY`.

### Optional build args

The default image includes Python, Node.js, Go, PHP 8.4, Docker CLI, Docker Compose, and the platform CLIs. Extra runtimes are build-time choices:

```bash
INSTALL_JAVA=true INSTALL_RUBY=true INSTALL_SWIFT=true INSTALL_ELIXIR=true INSTALL_RUST=true task build
```

Supported optional args: `INSTALL_JAVA`, `INSTALL_RUBY`, `INSTALL_SWIFT`, `INSTALL_ELIXIR`, `INSTALL_NVM`, and `INSTALL_RUST`.

## Security model

Docker helps keep this setup contained, but it is not a hardened sandbox.

By default, the stack:

- runs OpenCode as the non-root `opencode` user via `gosu`
- publishes OpenCode and OpenChamber on `127.0.0.1`
- persists only the configured container home mount, usually `./data/home`
- does not mount the host Docker socket
- does not mount host-level `~/.ssh` or `~/.gitconfig`

Important boundaries:

- Files under `OPENCODE_HOME_DIR` are host files. Container tools can read and write them.
- API keys, tokens, and passwords passed as environment variables are available to container processes.
- Interactive auth for `gh`, `glab`, `cntb`, and `atlcli` is stored in the mounted container home.
- The init script can generate an SSH key inside the mounted home. It is not your host SSH key unless you put it there.
- The container has network access for model providers, package registries, Git hosts, and tunnel services.
- `OPENCODE_BIND_ADDRESS=0.0.0.0` publishes ports on all host interfaces.
- The Docker override mounts `/var/run/docker.sock`, which gives access to the host Docker daemon.
- Cloudflare tunnel profiles expose the service over the internet. Set `OPENCODE_SERVER_PASSWORD` first.

> [!WARNING]
> Use Docker socket mode and public tunnel mode only for trusted local workflows with explicit authentication.

## Supported tools and models

### Agent tooling

- [OpenCode](https://github.com/opencode-ai/opencode), installed from npm
- [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent), installed during the image build and seeded into OpenCode config
- OpenChamber as an optional web UI
- `agent-browser` with an image-local browser runtime
- OpenCode skills from `bootstrap/skills/`
- OmO teams from `bootstrap/omo/teams/`

### Model providers

The seeded OpenCode config defines:

- Z.AI Coding Plan provider via `OCD_ZHIPU_API_KEY`
- GLM models: `glm-5.1`, `glm-5-turbo`, `glm-4.7`, and `glm-4.5-air`
- Google provider via `OCD_GEMINI_API_KEY`
- Gemini model: `gemini-2.5-flash`

Compose can render with an empty Gemini key because the variable is not checked during Compose interpolation. Keep `OCD_GEMINI_API_KEY` set for normal use, otherwise OmO visual tasks do not have a working multimodal model.

### Platform and language tools

Bundled platform tools include `gh`, `glab`, `cntb`, `atlcli`, `cloudflared`, `docker`, `docker compose`, `jq`, `yq`, `git`, and `curl`.

Default language/runtime support includes Node.js, Python/pyenv, Go, PHP 8.4, Composer, and shell tooling. Java, Ruby, Swift, Elixir/Erlang, nvm-managed Node.js, and Rust are optional build-time installs.

## Development workflow

Use `Taskfile.yml` for local work:

| Task | Purpose |
| --- | --- |
| `task config` | Render the effective Compose config. |
| `task build` | Build the image with BuildKit. |
| `task up` | Start the OpenCode stack in the background. |
| `task logs` | Follow the `opencode` service logs. |
| `task shell` | Open a shell in the running container. |
| `task opencode -- ...` | Run `opencode` in the running container. |
| `task migrate-env` | Rename legacy `.env` keys and add missing entries from `.env.example`. |
| `task test-unit` | Run Bats unit tests. |
| `task test-lint` | Run Bats lint/structure tests. |
| `task test-integration` | Build and boot the real Compose stack, then check runtime behavior. |
| `task test` | Run unit, integration, and lint suites. |

### Docker socket override

Use the Docker override when OpenCode needs to run Docker commands against the host daemon:

```bash
WITH_DOCKER=true task up
docker compose -f docker-compose.yml -f docker-compose.docker.yml exec opencode docker version
```

The override mounts `/var/run/docker.sock` and sets `DOCKER_HOST=unix:///var/run/docker.sock`.

### OpenChamber

OpenChamber can run next to the default OpenCode web UI:

```bash
OPENCHAMBER_ENABLED=true
OPENCHAMBER_PORT=4020
OPENCHAMBER_UI_PASSWORD=change-me
task up
open http://localhost:4020
```

### Cloudflare tunnels

Quick tunnel:

```bash
task tunnel-quick
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml logs cloudflared
```

Managed tunnel:

```bash
CF_TUNNEL_TOKEN=... task tunnel-managed
```

Use `task tunnel-down` to stop tunnel services without stopping OpenCode.

## Testing and verification

Local checks are Bats-based and live in `tests/`:

```bash
task test-unit
task test-lint
task test-integration
task test
```

The integration suite boots the real Compose stack, waits for the OpenCode health endpoint, checks the active OpenCode config path, verifies OmO plugin loading, and confirms bundled CLIs such as `agent-browser`, `gh`, `glab`, `cntb`, `atlcli`, and `cloudflared`.

For a quick docs/config check:

```bash
OCD_ZHIPU_API_KEY=dummy OCD_GEMINI_API_KEY=dummy docker compose config --quiet
```

GitHub Actions defines two workflows:

- `Build` runs `docker build -t opencode-docker:test .` on pushes to `master` and pull requests.
- `Testing` runs `task test-unit`, `task test-lint`, and `task test-integration` on pushes to `master` and pull requests.

## Limitations

- This is a local developer environment, not a hardened multi-tenant sandbox.
- The mounted container home is host data, even though the tools run in Docker.
- Docker socket mode can control the host Docker daemon, so it stays opt-in.
- Public tunnel mode depends on correct OpenCode/OpenChamber authentication.
- Optional runtime support follows the current Dockerfile download paths and is not equally portable across CPU architectures.
- Tests cover scripts, Compose rendering, stack boot, config seeding, and bundled tool availability. They do not prove that every upstream OpenCode, OmO, provider, or CLI feature works in every workflow.
- Model behavior still depends on upstream providers, valid API keys, network access, and session prompts/config.
