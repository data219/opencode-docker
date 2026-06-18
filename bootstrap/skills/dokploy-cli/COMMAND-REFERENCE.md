# Command Reference

This appendix is a snapshot, not normative policy. SKILL.md is the normative source for agent behavior, approval gates, credential handling, and direct API fallback rules.

Snapshot source: upstream Dokploy CLI repository at `Dokploy/cli`, with command group and generation notes checked against commit `e3e3c875812d4218edc710d9033f44011c231b8d` from the planning references. Snapshot date context: 2026-06-18. Treat this file as a dated aid for command discovery and safety review, not a promise that every installed CLI version has the same commands.

## Safe local discovery

Use local help output to discover the installed CLI surface. These checks do not contact the Dokploy server for project data.

```sh
dokploy --help
dokploy --version
dokploy <group> --help
```

Representative help groups seen in Dokploy CLI documentation include `application`, `project`, `postgres`, `redis`, `settings`, and `user`. This is intentionally not a maintained list of all generated commands. The CLI has many generated commands, and agents should discover the specific installed command with help output before use.

Read-only local smoke checks should stay limited to help and version commands by default:

```sh
dokploy --help
dokploy --version
dokploy project --help
dokploy application --help
```

Do not use live data-returning read commands as default validation. For example, `dokploy project all --json` is read-oriented but potentially sensitive because it can expose live server names, IDs, URLs, deployment state, or other operational data. Mention or run live data-returning read commands only when optional, with explicit user approval, and only when their output is needed for the task.

## Safety categories

Classify commands by likely side effect before running them. When uncertain, use `dokploy <group> --help`, inspect command wording, and apply the stricter category.

| Category | Default handling | Examples |
| --- | --- | --- |
| Local discovery | Safe by default | `dokploy --help`, `dokploy --version`, `dokploy <group> --help` |
| Live read | Optional only with user approval when data may be exposed | list, get, inspect, status, logs, all |
| Write or action | Requires explicit user approval before execution | create, update, delete, deploy, restart, stop, cancel, rollback, remove, save |
| Configuration or credentials | Treat as sensitive even when local | login, setup, save, config, token, key |

High-risk verbs to gate: create, update, delete, deploy, restart, stop, cancel, rollback, remove, save.

Read-only does not mean harmless. Read commands can still reveal sensitive live server data, including application names, environment names, domains, resource IDs, deployment history, logs, and user or team information. Prefer narrow commands, avoid printing unnecessary JSON, and redact sensitive output in notes or final responses.

## Generated command guidance

The upstream Dokploy CLI generates many commands from the Dokploy API schema. In generated code, `apiGet` generally maps to read operations, while `apiPost` generally maps to writes or actions. This mapping is a useful clue, not a complete safety decision.

Safety still depends on both output and side effects:

* An `apiGet` command may be read-only but return sensitive live server data.
* An `apiPost` command should be treated as write or action oriented unless proven otherwise.
* Command names with action verbs such as deploy, restart, cancel, rollback, stop, remove, save, create, update, or delete need explicit user approval before execution.

Do not bypass the CLI with direct API calls just because the generated implementation is visible. Follow `SKILL.md` for the direct API fallback rule.

## Refresh procedure

Use this refresh procedure when the upstream Dokploy CLI changes, when validation detects drift, or before relying on a command group that is missing from local help output.

1. Check the installed CLI locally with `dokploy --version` and `dokploy --help`.
2. Compare against the upstream `Dokploy/cli` repository, especially the generated command documentation and generated command source.
3. Review the upstream OpenAPI generation workflow, including the command generation script and generated command output, instead of hand-maintaining an exhaustive table.
4. Update only representative groups, safety categories, and drift notes in this appendix.
5. Re-run the repository validation that checks required safety phrases and prevents accidental exhaustive command lists.

Keep this appendix concise. The correct way to learn a specific command is local discovery with help output, followed by the safety policy in `SKILL.md`.
