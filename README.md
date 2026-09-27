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
- A Z.AI Coding Plan API key for the `zai-coding-plan` variant (optional if you use OpenAI default)
- Optional: a Google AI Studio API key for the Gemini vision model used by the Z.AI variant and OmO visual tasks
- Optional: a ChatGPT Plus/Pro subscription for the `openai-chatgpt` config variant

### Start the stack

```bash
git clone https://github.com/data219/opencode-docker.git
cd opencode-docker

cp .env.example .env
# Edit .env to match your preferred variant (default: openai-chatgpt).
# Optional: OPENCODE_CONFIG_VARIANT=zai-coding-plan requires OCD_ZHIPU_API_KEY.
# Optional: set OCD_GEMINI_API_KEY for OmO visual tasks.

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

The default config variant is `openai-chatgpt`. It uses OpenCode's built-in OpenAI flow and does not need `OCD_ZHIPU_API_KEY` to start.
Set `OPENCODE_CONFIG_VARIANT=zai-coding-plan` to switch to Z.AI defaults (requires a Z.AI key).
Compose allows the variable to be empty when using `openai-chatgpt`; the Z.AI variant also needs `OCD_GEMINI_API_KEY` for vision tasks.

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENCODE_CONFIG_VARIANT` | `openai-chatgpt` | Selects managed config variant (`openai-chatgpt` or `zai-coding-plan`). |
| `OCD_ZHIPU_API_KEY` | optional | Z.AI Coding Plan API key used by `zai-coding-plan`. |
| `OCD_GEMINI_API_KEY` | empty | Optional Google AI Studio key for the Gemini vision model used by the Z.AI variant and OmO visual tasks. |
| `OPENCODE_MODE` | `web` | OpenCode server mode: `web` or `serve`. |
| `OPENCODE_PORT` | `4000` | OpenCode port inside the container and on the host. |
| `OPENCODE_BIND_ADDRESS` | `127.0.0.1` | Host interface Docker publishes to. Use `0.0.0.0` only with auth. |
| `OPENCODE_SERVER_USERNAME` | OpenCode default | Optional basic-auth username. Empty values are not forwarded. |
| `OPENCODE_SERVER_PASSWORD` | empty | Optional basic-auth password. Set this before exposing ports beyond localhost. |
| `OPENCODE_CORS` | empty | Optional single CORS origin passed to OpenCode. |
| `OPENCODE_PRINT_LOGS` | `false` | Streams OpenCode logs to container stderr. |
| `OPENCODE_LOG_LEVEL` | empty | Optional `DEBUG`, `INFO`, `WARN`, or `ERROR`. |
| `OPENCODE_HOME_DIR` | `./data/home` | Host path mounted as `/home/opencode`. |
| `OPENCODE_DOTFILES_REPO` | empty | Optional trusted Git dotfiles repo installed into the persisted home on first startup or when the repo value changes. |
| `OPENCHAMBER_ENABLED` | `false` | Starts OpenChamber alongside OpenCode. |
| `OPENCHAMBER_PORT` | `4020` | OpenChamber port inside the container and on the host. |
| `OPENCHAMBER_UI_PASSWORD` | empty | Optional OpenChamber UI password. Set this for non-local exposure. |
| `OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN` | `true` | Allows OpenChamber to bind `0.0.0.0` without UI auth. Keep host binding local unless you accept unauthenticated LAN access. |
| `FORCE_SKILL_SYNC` | `false` | Replaces bootstrapped skills with image defaults when set to `true`. |
| `GH_TOKEN` / `GITHUB_TOKEN` | empty | Non-interactive GitHub CLI auth; also used as optional BuildKit secrets for GitHub-hosted CLI downloads and private GitHub HTTPS dotfiles clones. Create a fine-grained token at <https://github.com/settings/personal-access-tokens/new>. |
| `GLAB_TOKEN` / `GITLAB_TOKEN` | empty | Non-interactive GitLab CLI auth. |
| `CNTB_OAUTH2_*` | empty | Contabo CLI auth. Set all four OAuth2 variables together. |
| `ATLCLI_*` | empty | Atlassian CLI token and profile defaults. |
| `DOKPLOY_URL` / `DOKPLOY_API_KEY` | empty | Non-interactive Dokploy CLI auth. |

Run `task migrate-env` after pulling changes if your `.env` still uses old names such as `ZHIPU_API_KEY` or `GEMINI_API_KEY`.

### Dotfiles

Set `OPENCODE_DOTFILES_REPO` in `.env` to install a trusted dotfiles repository into the container home. The stack follows the GitHub Codespaces installer order: `install.sh`, `install`, `bootstrap.sh`, `bootstrap`, `script/bootstrap`, `setup.sh`, `setup`, then `script/setup`.

For private GitHub HTTPS repositories, set `GH_TOKEN` or `GITHUB_TOKEN` with repository read access. Create a fine-grained token directly at <https://github.com/settings/personal-access-tokens/new>, select the dotfiles repository, and grant read-only repository contents access. The startup script uses a temporary Git askpass helper for the clone and does not write the token into the repo marker or Git config. SSH URLs such as `git@github.com:owner/dotfiles.git` also work when the persisted container SSH key or a deploy key has access.

If no installer is present, hidden files and folders from the repo are symlinked into `/home/opencode` when the target does not already exist. Dotfiles scripts can run arbitrary commands; only configure repositories you trust.

### Config variants

Seeded OpenCode and Oh My OpenAgent config lives in `bootstrap/config/variants/`. The default variant is `openai-chatgpt`.

Switch variants with:

```bash
task config-switch -- openai-chatgpt
task config-switch -- zai-coding-plan
```

The switch writes these managed files under `${OPENCODE_HOME_DIR:-./data/home}/`:

- `.config/opencode/opencode.json`
- `.omo/omo.jsonc`
- `.config/opencode/.opencode-docker-config-version`

`AGENTS.md` is seeded only when it does not already exist.

For the `openai-chatgpt` variant, start the stack and run the first-time OpenAI ChatGPT login inside OpenCode:

```bash
task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"
```

This uses OpenCode's built-in OpenAI OAuth/device login for ChatGPT Plus/Pro subscriptions. It is not configured in `.env`, does not need `OPENAI_API_KEY`, and persists the login state in `OPENCODE_HOME_DIR`.

### Optional build args

The default image includes Python, Node.js, Go, PHP 8.4, Docker CLI, Docker Compose, platform CLIs, and OpenCode LSP server commands. Extra runtimes are build-time choices:

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
- Docker socket mode mounts `/var/run/docker.sock`, which gives access to the host Docker daemon.
- Cloudflare tunnel profiles expose the service over the internet. Set `OPENCODE_SERVER_PASSWORD` first.

> [!WARNING]
> Use Docker socket mode and public tunnel mode only for trusted local workflows with explicit authentication.

## Supported tools and models

### Agent tooling

- [OpenCode](https://github.com/opencode-ai/opencode), installed from npm
- [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent), installed during the image build and seeded into OpenCode config
- OpenChamber as an optional web UI
- `agent-browser` with an image-local browser runtime
- OpenSpec CLI for spec-driven development with OpenCode command generation
- OpenCode skills from `bootstrap/skills/`
- OmO teams from `bootstrap/omo/teams/`

To enable OpenSpec in a project mounted into the stack, run:

```bash
openspec init --tools opencode
```

OpenSpec writes project-local `.opencode/skills/` and `.opencode/commands/opsx-*.md` files. After that, use commands such as `/opsx:propose` from OpenCode in that project.

### Model providers

The default `openai-chatgpt` config uses OpenCode's built-in OpenAI provider and an OmO OpenAI-only model map through ChatGPT Plus/Pro OAuth. `OPENAI_API_KEY` is not used for subscription auth.

OmO 5 loads its managed configuration from `~/.omo/omo.jsonc`. The tracked variant seeds use the `[opencode]` harness section to retain agent models, categories, fallbacks, prompts, and concurrency limits. Both `deep-low` and `deep-high` are explicitly configured: the OpenAI variant separates normal execution from premium escalation. `task config-switch` updates this file as well as OpenCode's config; existing legacy OmO files are left in place for reference.

Automatic continuation uses OmO 5's enabled Goal mode. The removed `default_mode.ralph_loop`, `experimental.auto_resume`, and `browser_automation_engine.provider=agent-browser` settings are no longer valid in this version. The installed `agent-browser` CLI remains available independently of OmO's built-in browser-provider selection.

The OpenAI variant uses only standard GPT-6 models: Sol for sustained work, Luna for research/quick tasks, and Astra for selected high-leverage roles. This is a quota-conscious policy, not a blanket GPT-5.6 Sol → Astra tier replacement. GPT-6 Astra's standard per-token Codex credit rate is 2.5× GPT-5.6 Sol's; GPT-6 Sol's is half. Fast mode uses 2.5× the standard GPT-6 credit rate where available. These rates do not prove a particular saving per task or included-plan quota. [Official pricing](https://learn.chatgpt.com/docs/pricing)

The comparison below is against the **pinned OmO 5.0.1 OpenCode/OpenAI-only path**, not moving `dev` documentation or its multi-provider/native defaults. `Sol5` and `Terra5` denote GPT-5.6; all selected models are GPT-6. Sources: [agent requirements](https://github.com/code-yeongyu/oh-my-openagent/blob/ab725f3299cd5ba8727a999817db8f9d856f2440/packages/model-core/src/agent-model-requirements.ts), [category requirements](https://github.com/code-yeongyu/oh-my-openagent/blob/ab725f3299cd5ba8727a999817db8f9d856f2440/packages/model-core/src/category-model-requirements.ts), [OpenAI-only overrides](https://github.com/code-yeongyu/oh-my-openagent/blob/ab725f3299cd5ba8727a999817db8f9d856f2440/packages/omo-opencode/src/cli/openai-only-model-catalog.ts), and [installer resolution](https://github.com/code-yeongyu/oh-my-openagent/blob/ab725f3299cd5ba8727a999817db8f9d856f2440/packages/omo-opencode/src/cli/model-fallback.ts).

| Agent/category | OmO 5.0.1 OpenAI choice | Selected choice and reason for deviation |
| --- | --- | --- |
| Sisyphus, Atlas, Sisyphus-Junior | Sol5 `medium` | Sol `medium`: quota-conscious workhorse for repeated orchestration/execution; not a claim of identical capability to Astra. Junior no longer uses Spark. |
| Hephaestus | Sol `medium` | Same as upstream; no deviation. |
| Prometheus, Metis | No OpenAI rung; installer ultimately emits `opencode/gpt-5-nano` | Sol `high`: deliberate OpenAI-only override for serious planning and gap analysis, not a provider-availability last resort. |
| Oracle | Sol5 `xhigh` | Astra `high`: targeted premium architecture/debugging consultant with bounded effort. The effort/capability balance is a policy choice, not a measured equivalence. |
| Momus | Astra `xhigh` | Same as upstream; review gate gets the recommended premium model. |
| Explore, Librarian | Luna Fast `low` | Luna `low`: same utility tier/effort, standard service instead of priority premium. |
| Multimodal-Looker | Sol5 `low` | Sol `low`: current workhorse model, upstream effort adopted rather than the previous `medium`. |
| Ultrabrain | Astra `max` | Same as upstream; reserved maximum-reasoning escalation. |
| Deep-Low | Sol5 Fast `medium`, then Sol5 `medium` | Sol `medium`: standard execution lane without priority premium; also shown as an explicit override in the [versioned installation guide](https://github.com/code-yeongyu/oh-my-openagent/blob/ab725f3299cd5ba8727a999817db8f9d856f2440/docs/guide/installation.md#L684-L697). |
| Deep-High | Astra `xhigh` | Same as upstream; restores the intended distinction from Deep-Low. |
| Visual-Engineering | OpenAI-only override: Sol5 `high` | Sol `high`: workhorse choice for UI work; preserves upstream effort without promoting every task to Astra. |
| Artistry | OpenAI-only override: Sol5 `xhigh` | Sol `xhigh`: creative workhorse with upstream effort; Astra remains reserved for the explicit escalation lanes. |
| Unspecified-Low, Unspecified-High | Terra5 `high` (High uses Low's chain without Claude Max20) | Sol `high`: current balanced tier; adopts upstream effort. General work is not the trivial Quick lane. |
| Writing | Claude-only; omitted by OpenAI-only installer | Sol `medium`: retain the existing writing function without requiring another provider; explicit custom lane, not an upstream OpenAI recommendation. |

Custom fallback chains also intentionally differ: Astra → Sol → Luna; Sol → Luna; Luna → Sol. They stay within the existing OpenAI sign-in and do not silently escalate economical roles to Astra. Smaller fallback models mean degraded capability, not equivalent results, and OpenAI-wide outages/quota exhaustion may affect every rung. All rungs support the configured effort. Runtime fallback still handles only 429/503/529 with the existing three-attempt limit and cooldown; it is not an authentication or missing-model repair mechanism. GPT-5.4/mini and Spark were removed from primary and fallback mappings because their ChatGPT-sign-in availability ended. [Model retirement guidance](https://learn.chatgpt.com/docs/models#deprecated-codex-models), [Spark deprecation](https://learn.chatgpt.com/docs/changelog)

Astra background concurrency remains one; Sol and Luna are two each, with provider concurrency three. These are scheduling limits, not a spend/quota cap. Existing prompt additions, retry timing, and the Z.AI variant remain unchanged. The integration check verifies all 11 agents and nine categories through OmO's active-harness diagnostic output; it does not make paid model calls or prove account-specific OAuth entitlement.

OmO 5.0.1 does not pass Prometheus's `high` or Sisyphus-Junior's `medium` effort to OpenCode's registered-agent variant field. The OpenAI variant therefore loads a small image-local compatibility plugin after OmO. It sets only these two missing variants and defers to an upstream fix if one is present. The integration suite checks the effective registered-agent state, not just OmO's diagnostic output. Revalidate this adapter when upgrading OmO or changing either agent's effort; Junior's factory currently reports a fixed `medium` default, so a different configured effort would require updating the adapter and test. No paid model calls or OAuth entitlement checks are made.

To back out premium routing while keeping OmO 5/GPT-6, use Sol `high` for Oracle/Deep-High and Sol `xhigh` for Momus/Ultrabrain in the tracked OpenAI seed. Remove each redundant Sol fallback and the unused Astra concurrency entry, and increment the config-version marker above the deployed value before rebuilding. A lower marker does not trigger re-seeding. Before upgrading, back up the persisted home; a full downgrade to OmO 4 requires restoring its legacy config alongside the old image, not just reverting the image tag. Do not restore retired ChatGPT-sign-in models as a backout plan.

Switch to `zai-coding-plan` for Z.AI/Gemini-driven defaults:

- Z.AI Coding Plan provider via `OCD_ZHIPU_API_KEY`
- GLM models: `glm-5.1`, `glm-5-turbo`, `glm-4.7`, and `glm-4.5-air`
- Google provider via `OCD_GEMINI_API_KEY`
- Gemini model: `gemini-2.5-flash`

Compose can render with an empty Gemini key because the variable is not checked during Compose interpolation. Keep `OCD_GEMINI_API_KEY` set when using a multimodal setup; otherwise visual tasks lack a working model.

### Platform and language tools

Bundled platform tools include `gh`, `glab`, `cntb`, `atlcli`, `dokploy`, `cloudflared`, `openspec`, `docker`, `docker compose`, `ansible`, `terraform`, `kubectl`, `helm`, `jq`, `yq`, `rg`, `shellcheck`, `git`, `zsh`, `curl`, and `wget`.

Default language/runtime support includes Node.js, Python/pyenv, Go, PHP 8.4, Composer, and shell tooling. OpenCode LSP support is enabled in the seeded config for built-in PHP, JavaScript/TypeScript, Go, Bash, Lua, Python, Terraform, Rust, and YAML servers. Markdown uses a custom `marksman` server entry.

The image installs the LSP server commands `intelephense`, `typescript-language-server`, `gopls`, `bash-language-server`, `vue-language-server`, `lua-language-server`, `pyright-langserver`, `terraform-ls`, `rust-analyzer`, `yaml-language-server`, and `marksman`. The full Rust toolchain remains optional through `INSTALL_RUST=true`; the default image includes `rust-analyzer` for Rust LSP support but not `rustc` or Cargo.

Java, Ruby, Swift, Elixir/Erlang, nvm-managed Node.js, and the full Rust toolchain are optional build-time installs.

## Development workflow

Use `Taskfile.yml` for local work:

| Task | Purpose |
| --- | --- |
| `task config` | Render the effective Compose config. |
| `task build` | Build the image with BuildKit. |
| `task up` | Start the OpenCode stack in the background. |
| `task logs` | Follow the `opencode` service logs. |
| `task config-switch -- <variant>` | Switch persisted OpenCode config, for example `openai-chatgpt` or `zai-coding-plan`. |
| `task shell` | Open a shell in the running container. |
| `task opencode -- ...` | Run `opencode` in the running container. |
| `task migrate-env` | Rename legacy `.env` keys and add missing entries from `.env.example`. |
| `task test-unit` | Run Bats unit tests. |
| `task test-lint` | Run Bats lint/structure tests. |
| `task test-integration` | Build and boot the real Compose stack, then check runtime behavior. |
| `task test` | Run unit, integration, and lint suites. |

### Docker socket mode

Enable Docker socket mode when OpenCode needs to run Docker commands against the host daemon.
Uncomment only this setting in `.env`:

```bash
OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock
```

Compose derives the container Docker environment from `OPENCODE_DOCKER_SOCKET_BIND`.
Verify it with:

```bash
task up
docker compose exec opencode docker version
```

Docker socket access is effectively host-root equivalent because it can control the host Docker daemon.

### OpenChamber

OpenChamber can run next to the default OpenCode web UI:

```bash
OPENCHAMBER_ENABLED=true
OPENCHAMBER_PORT=4020
OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN=true
OPENCHAMBER_UI_PASSWORD=change-me
task up
open http://localhost:4020
```

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

## Testing and verification

Local checks are Bats-based and live in `tests/`:

```bash
task test-unit
task test-lint
task test-integration
task test
```

The integration suite boots the real Compose stack, waits for the OpenCode health endpoint, checks the active OpenCode config path, verifies OmO plugin loading, and confirms bundled CLIs such as `agent-browser`, `gh`, `glab`, `cntb`, `atlcli`, `openspec`, and `cloudflared`. It also checks that the default OpenCode LSP server commands are available in the running container.

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
