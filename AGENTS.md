# Repo Notes

## Dockerfile Version Pinning

- Keep third-party tool versions centralized in `Dockerfile` as top-level `ARG` values instead of inline literals inside URLs or shell snippets.
- For every version that should be maintained by Renovate, add a preceding `# renovate:` comment with the correct `datasource`, `depName`, and optional `versioning`/`packageName`.
- When a dependency cannot be detected by Renovate's built-in Dockerfile support, add or update a `customManagers` regex rule in `renovate.json`.
- After changing Renovate config, validate it with:
  - `docker run --rm -v "$PWD:/repo" -w /repo renovate/renovate:39 renovate-config-validator`
- Prefer version formats that can be mapped back into download URLs without extra manual edits when Renovate proposes upgrades.

## CI Integration Test Diagnostics

- For Docker-based integration tests in GitHub Actions, prefer CI-safe startup and health-check timeouts over aggressive local-only values.
- When a container health wait times out in CI, print `docker compose ps` and relevant service logs before failing so the next debugging step has actionable evidence.
- If a first CI fix changes the failure mode, re-run and reclassify the new failure before assuming the original root cause is still active.
- When a managed config file changes, bump both `bootstrap/config/.opencode-docker-config-version` and `data/config/.opencode-docker-config-version` so existing volumes get the updated managed seed.
- Docker-backed integration tests should avoid a single fixed host port; derive a per-run port or allow env override to prevent local port collisions.
- For image-level browser automation changes, verify both the installed binary and the final seeded runtime config inside the booted container.
- For browser-runtime fixes, verify both the required shared libraries and the effective browser executable path inside the running container; missing `.so` files and bind-mounted home directories can fail independently.
- When `/home/opencode` is bind-mounted, do not depend on browser binaries that were installed only under the image user's home; prefer an image-local executable path or another location not shadowed by the mount.
- For `agent-browser` coverage, do not stop at `command -v agent-browser`; add a runtime smoke test that actually opens a page and writes a PDF from inside the compose stack.
- For entrypoint or privilege-drop tests that mock executables and then switch users via `gosu`, make the mock binary directory traversable (for example `chmod 755 "$MOCK_BIN_DIR"`), otherwise the target user may miss the mock and start the real binary.
- For runtime checks that depend on user-scoped config or `$HOME`, run `docker compose exec -T -u <user> <service> ...` with the intended runtime user instead of root.
- When a bind-mounted home is created by Docker as `root`, ensure startup init logic recreates and re-owns writable runtime directories such as `.config` and `.cache` before validating browser or app startup behavior.
- For OpenCode runtime/plugin assertions, verify the active config path first with `opencode debug paths`; do not treat seeded file existence alone as proof that runtime config was loaded.

## Behavior-Only Test Guardrails

- Do not patch repository scripts inside tests with `sed`, copied temp variants, or similar text rewrites just to redirect collaborators; prefer explicit env-driven test seams such as overrideable script paths.
- Keep project tests focused on observable behavior, exit codes, ownership, health, command output, and file existence. Do not keep helper assertions whose primary purpose is checking file contents.
- When mocking command execution in Bats, assert only the relevant invoked arguments or side effects; do not couple tests to the current host/container username unless that identity is the behavior under test.

## Dockerfile Ownership Performance

- Avoid global recursive ownership rewrites like `chown -R ... /home/opencode` in late Dockerfile layers when large toolchains live under that tree.
- Prefer targeted `chown` only on root-created runtime seed paths (for example config/state/workspace directories) to prevent large metadata-only layers and slow no-cache builds.
- If a build appears stuck on ownership steps, inspect `docker history` layer size first before changing unrelated install steps.
