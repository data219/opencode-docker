# Single Compose Env Controls Design

## Goal

Unify the current three Compose files into one `docker-compose.yml` and make optional Docker socket and Cloudflare tunnel behavior controllable from `.env`.

## Current State

The repository currently uses:

- `docker-compose.yml` for the base `opencode` service.
- `docker-compose.docker.yml` to mount `/var/run/docker.sock` and set Docker-related environment.
- `docker-compose.tunnel.yml` for Cloudflare quick and managed tunnel services.

`Taskfile.yml`, `.env.example`, `README.md`, and `tests/lint/test_compose.bats` reference the overlay files directly. Existing Compose validation requires at least a dummy `OCD_ZHIPU_API_KEY`.

## Target Architecture

`docker-compose.yml` becomes the only Compose file for normal repository use.

The main service remains named `opencode`. It keeps the existing build, ports, volume, environment, restart, secrets, and healthcheck behavior. The Docker socket mount moves into this service and is controlled by an environment-substituted host path.

Cloudflare tunnel services move into `docker-compose.yml`:

- `cloudflared` uses profile `tunnel-quick`.
- `cloudflared-managed` uses profile `tunnel-managed`.

The old overlay files are removed after their behavior is represented in the single Compose file and covered by tests.

## Runtime Controls

The `.env` file is the central control surface.

Default behavior remains local and conservative:

```env
COMPOSE_PROFILES=
OPENCODE_DOCKER_SOCKET_BIND=/dev/null
```

Docker socket mode is enabled by setting:

```env
OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock
```

Compose derives the container `OPENCODE_DOCKER_SOCKET` and `DOCKER_HOST` values from `OPENCODE_DOCKER_SOCKET_BIND`. `OPENCODE_DOCKER_SOCKET` uses the container mount path `/var/run/docker.sock`, even when the host bind source uses another socket path. Ambient host values for `OPENCODE_DOCKER_SOCKET` and `DOCKER_HOST` must not activate Docker access by themselves.

This keeps the service name `opencode` while avoiding a second profiled OpenCode service. The `/dev/null` default makes the socket bind inert unless the user opts in.

Quick tunnel mode is enabled with:

```env
COMPOSE_PROFILES=tunnel-quick
```

Managed tunnel mode is enabled with:

```env
COMPOSE_PROFILES=tunnel-managed
CF_TUNNEL_TOKEN=...
```

Only one tunnel profile should be active for normal use.

## Taskfile Design

`Taskfile.yml` stops composing command strings with extra `-f` files. The standard tasks use plain `docker compose`:

- `task config`
- `task build`
- `task up`
- `task logs`
- `task shell`
- `task opencode`

Tunnel convenience tasks remain:

- `task tunnel-quick` runs `COMPOSE_PROFILES=tunnel-quick docker compose up -d`.
- `task tunnel-managed` runs `COMPOSE_PROFILES=tunnel-managed docker compose up -d`.
- `task tunnel-down` stops and removes `cloudflared` and `cloudflared-managed` without overlay files.

Docker socket mode no longer needs a `WITH_DOCKER` Task variable. Users enable it in `.env`.

## Env Example and Migration

`.env.example` includes commented, ready-to-uncomment blocks for:

- enabling Docker socket delegation,
- enabling the quick Cloudflare tunnel,
- enabling the managed Cloudflare tunnel.

`scripts/migrate-env.sh` remains the update path for existing `.env` files. It continues to append missing variables from `.env.example` without activating commented examples.

The migration also preserves old active Docker socket intent:

- If an existing `.env` has `OPENCODE_DOCKER_SOCKET=/var/run/docker.sock` active and no `OPENCODE_DOCKER_SOCKET_BIND`, migration adds `OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock`.
- If no active Docker socket variable exists, migration leaves the Docker socket example commented and inactive.

No migration step should enable tunnel profiles automatically.

## Documentation

`README.md` is updated to describe one Compose file and `.env`-driven optional behavior.

The Docker socket section shows the `.env` lines to uncomment and uses `task up` plus `docker compose exec opencode docker version`.

The Cloudflare tunnel section explains `COMPOSE_PROFILES=tunnel-quick` and `COMPOSE_PROFILES=tunnel-managed`, keeps the password warning, and removes all `-f docker-compose.tunnel.yml` examples.

The security model keeps the existing warnings:

- Docker socket mode gives the container access to the host Docker daemon.
- Tunnel mode exposes the service over the internet and requires explicit OpenCode authentication.

## Testing

The Bats lint tests cover Compose rendering through the single file:

- Base config renders without profiles.
- `COMPOSE_PROFILES=tunnel-quick` renders the quick tunnel service.
- `COMPOSE_PROFILES=tunnel-managed CF_TUNNEL_TOKEN=test` renders the managed tunnel service.
- Quick tunnel config does not require `CF_TUNNEL_TOKEN`.
- Docker socket env renders the `/var/run/docker.sock` mount and Docker environment for `opencode`.

The migration unit tests add a case for preserving active Docker socket intent by adding `OPENCODE_DOCKER_SOCKET_BIND=/var/run/docker.sock`.

The existing integration suite continues to boot the base stack. It does not need to start public tunnels.

## Risks and Trade-offs

Compose profiles cannot activate individual fields inside an existing service. Docker socket mode therefore uses an environment-substituted bind mount instead of a profile.

The `/dev/null` fallback is intentionally inert, but it still means `opencode` always has a bind mount entry. Tests must verify the active Docker socket case so future edits do not break the opt-in path.

`COMPOSE_PROFILES` in `.env` is standard Compose behavior and gives the requested one-file workflow, but users can accidentally enable both tunnel profiles. Documentation should recommend enabling only one tunnel profile for normal use.
