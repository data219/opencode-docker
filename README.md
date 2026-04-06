# data219/opencode-docker

Docker container for [OpenCode](https://github.com/opencode-ai/opencode) with [Oh-My-OpenAgent (OmO)](https://github.com/nimbleflux/oh-my-opencode) pre-configured for Z.AI Coding Plan (GLM-5).

**⚠️ Development-only container.** Not intended for production use.

## Upstream

Forked from [nimbleflux/opencode-docker](https://github.com/nimbleflux/opencode-docker).

## Features

- OpenCode AI coding assistant running in `web` or `serve` mode
- Oh-My-OpenAgent with GLM-5 model for all agent roles
- Multi-language development environment (Python, Node.js, Go, Rust, Bun, and more)
- Custom skills support via bind mount
- BuildKit cache mounts for fast rebuilds

## Quick Start

```bash
cp .env.example .env
# Edit .env — set ZHIPU_API_KEY
docker compose up -d
```

Open http://localhost:4000 in your browser.

## Building

Requires Docker BuildKit:

```bash
DOCKER_BUILDKIT=1 docker compose build
```

## License

MIT
