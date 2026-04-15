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
