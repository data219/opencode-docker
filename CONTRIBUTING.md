# Contributing to opencode-docker

Development setup, build internals, testing, and architectural decisions.

## Prerequisites

- Docker Engine with BuildKit support (`DOCKER_BUILDKIT=1`)
- [Task](https://taskfile.dev/) (for local build/test workflows)
- `gh` CLI (for upstream sync workflow)

## Building

```bash
task build
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
task build
```

| Build Arg       | Default  | What it installs           |
| --------------- | -------- | -------------------------- |
| `INSTALL_JAVA`  | `false`  | Java Temurin 21            |
| `INSTALL_RUBY`  | `false`  | Ruby 3.3                   |
| `INSTALL_SWIFT` | `false`  | Swift 6.0                  |
| `INSTALL_ELIXIR`| `false`  | Elixir + Erlang/OTP 27     |
| `OMO_VERSION`   | `3.14.0` | Oh-My-OpenAgent version    |

BuildKit cache mounts are used for pip, npm, and go module caches to speed up rebuilds.

## Testing

```bash
task test-all           # Run all test suites
task test-unit          # Fast, no Docker required
task test-lint          # Structural assertions (file existence, permissions)
task test-integration   # Boots the real Compose stack (single-threaded: --jobs 1)
```

Integration tests require Docker and boot the real `docker compose` stack with a health check plus runtime artifact validation.

## GitHub Actions QA

The repository uses two chained workflows:

- `Build`: runs `docker build -t opencode-docker:test .` directly to validate the Dockerfile without Compose.
- `Testing`: triggers after `Build` succeeds and runs `task test-unit`, `task test-lint`, and `task test-integration`.

## Dockerfile Structure

The Dockerfile follows a single-stage build with BuildKit cache mounts:

1. **Base**: Ubuntu 22.04 with minimal packages
2. **System tools**: `gh`, `yq`, `golangci-lint`, `jq`, `curl`, `git`
3. **Language runtimes**: Python (pyenv), Node.js (nvm), Go, Rust, PHP 8.4, Bun installed in `/opt/`
4. **Optional runtimes**: Java, Ruby, Swift, Elixir gated by build args
5. **OpenCode**: Binary installed from upstream release
6. **Oh-My-OpenAgent**: Installed from npm via `OMO_VERSION` build arg
7. **Bootstrap**: Config defaults and skills copied to `/opt/opencode-defaults/`
8. **Entrypoint**: `gosu` for non-root execution, init script for config seeding

## Config Seeding and Version Tracking

The init script (`scripts/docker-init.sh`) implements a two-tier seeding strategy:

### Managed configs (`.managed` suffix)

Files in `/opt/opencode-defaults/` with a `.managed` suffix are **always overwritten** from image defaults when the config version increases. The `.managed` suffix is stripped when copying to the user config dir.

Use this for configs where upstream changes must take effect (provider definitions, default model mappings).

### Non-managed configs

Regular files are only copied if they don't exist yet. Once the user has edited a file, it's never touched again.

### Version marker

`.opencode-docker-config-version` tracks the config schema version. When the image ships a higher version, managed configs are re-seeded and the entrypoint prints a warning about the upgrade.

### Config drift detection

`scripts/docker-entrypoint.sh` compares the version marker in the user config dir against the image defaults. If they differ, it warns the user but does **not** overwrite non-managed files.

## Skills Sync

`scripts/docker-init.sh` syncs `bootstrap/skills/` into `/home/opencode/.config/opencode/skills/`:

- `FORCE_SKILL_SYNC=false` (default): merge — new skills are copied, existing skills get missing files added, user modifications preserved
- `FORCE_SKILL_SYNC=true`: full reset — all skills replaced with bootstrap defaults

## Upstream Sync

This repo is forked from [nimbleflux/opencode-docker](https://github.com/nimbleflux/opencode-docker).

```bash
git remote add upstream https://github.com/nimbleflux/opencode-docker.git
git fetch upstream
git merge upstream/main --no-edit
# Resolve conflicts and test
task test-all
```

## Phase 2 (Future)

Separate branch targeting Ubuntu 24.04 with the full codex-universal language/tool set, mise version manager, multi-stage build evaluation, and ARM64 support.
