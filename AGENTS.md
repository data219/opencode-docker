# Repo Notes

## Dockerfile Version Pinning

- Keep third-party tool versions centralized in `Dockerfile` as top-level `ARG` values instead of inline literals inside URLs or shell snippets.
- For every version that should be maintained by Renovate, add a preceding `# renovate:` comment with the correct `datasource`, `depName`, and optional `versioning`/`packageName`.
- When a dependency cannot be detected by Renovate's built-in Dockerfile support, add or update a `customManagers` regex rule in `renovate.json`.
- After changing Renovate config, validate it with:
  - `docker run --rm -v "$PWD:/repo" -w /repo renovate/renovate:39 renovate-config-validator`
- Prefer version formats that can be mapped back into download URLs without extra manual edits when Renovate proposes upgrades.
