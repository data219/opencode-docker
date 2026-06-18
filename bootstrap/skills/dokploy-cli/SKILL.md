---
name: dokploy-cli
description: Use when a task involves Dokploy, Dokploy-hosted resources, deployments, projects, databases, domains, settings, users, or anything that could be handled by an installed dokploy command.
---

# Dokploy CLI Skill

## Source of Truth

This `SKILL.md` is the normative policy for Dokploy work. Other files may explain installation, command discovery, or validation, but this file controls agent behavior.

Use the **Dokploy CLI** as the first path for Dokploy tasks. If `dokploy` is installed and can satisfy the request, use it instead of **direct Dokploy API** calls.

## When to Use

Use this skill when the user asks about Dokploy resources, deployment status, applications, projects, databases, domains, certificates, backups, server settings, users, or CLI based Dokploy automation.

Do not use this skill for unrelated hosting platforms or for general shell work that does not touch Dokploy.

## Routing Rules

1. Prefer `dokploy` commands over direct Dokploy API calls whenever the CLI is installed and can satisfy the request.
2. Use direct Dokploy API fallback only when the CLI is unavailable or clearly insufficient for the requested task.
3. Before any direct API fallback, get **explicit user approval** and write the reason in the work notes or final response.
4. Treat all create, update, delete, deploy, restart, stop, cancel, rollback, configuration, credential, and permission changes as **mutating**.
5. Do not run mutating Dokploy CLI operations until the user gives explicit user approval for the specific action.

## CLI Availability Checks

Check for the CLI with safe discovery commands only:

```sh
command -v dokploy
dokploy --help
dokploy --version
```

Use group help for command discovery, such as `dokploy application --help` or `dokploy project --help`. Help and version checks are safe default checks because they do not query live server data.

Do not inspect local Dokploy config or auth files. Do not print environment variables or config contents.

## Direct API Fallback Policy

Direct API fallback is an exception, not the normal path.

Only consider direct Dokploy API calls when:

- the CLI is unavailable, or
- the installed CLI cannot perform the requested read or action, or
- the user explicitly asks for API level work and approves the risk.

Before fallback, ask for explicit user approval and document why the CLI path is unavailable or insufficient. Do not include direct API helper code or direct API examples in docs, notes, or generated output unless the user explicitly approved that exact fallback and the content is necessary.

## Mutating Operation Approval Gate

Mutating operations require explicit user approval before execution, even when they use the Dokploy CLI.

Examples of mutating intent include commands or tasks involving create, update, delete, remove, deploy, redeploy, restart, stop, cancel, rollback, restore, import, save, set, enable, disable, assign, revoke, rotate, or changing configuration.

Approval must be specific enough to identify the target and action. If approval is vague, restate the command intent and wait for clear approval before running it.

## Read-Only Guidance

Read-only commands can still reveal sensitive data, such as project names, domains, service topology, user details, environment names, or deployment history.

For read-only requests:

- prefer help, version, and command discovery when verifying the CLI itself,
- use live data reads only when the user requested that information,
- request JSON output only when it helps the task and will not expose secrets in logs,
- summarize sensitive live output instead of pasting it when exact values are not needed.

Do not claim `apiGet` or any read command is always safe. Read-only means non-mutating, not non-sensitive.

## Credential Redaction Rules

Never reveal credentials or config contents. **do not print tokens**.

Redact values for all credential names, including:

- `DOKPLOY_API_KEY`
- `DOKPLOY_AUTH_TOKEN`
- `DOKPLOY_URL`

Also redact bearer tokens, session values, private URLs when sensitive, and any token-looking strings. Do not copy local CLI config contents into chat, docs, evidence, tests, or logs.

## Command Discovery

Use CLI help output instead of maintaining a manual exhaustive command list:

```sh
dokploy --help
dokploy <group> --help
dokploy <group> <command> --help
```

Prefer generated CLI commands when available. If command behavior is unclear, inspect help output first, then choose the smallest safe command that satisfies the user request.

## Verification Evidence

When changing this skill or related docs, record concise evidence that checks passed without secrets. Good evidence includes assertion output, static scan results, and notes that only safe discovery commands were run.

Evidence must not include real tokens, config contents, direct API command examples, or live sensitive server data.

## Common Mistakes/Rationalizations

| Mistake | Correct behavior |
|---|---|
| "The API is faster." | Use the Dokploy CLI when it is installed and can satisfy the request. |
| "This is only a small API read." | Prefer CLI reads, and remember read-only output can still expose sensitive data. |
| "I can run a deploy because the user asked about deployment." | A deploy is mutating. Get explicit user approval for the specific action first. |
| "The token is already in the environment." | Do not print tokens, environment values, or config contents. |
| "The CLI is missing, so API fallback is automatic." | Ask for explicit user approval and document why fallback is needed. |
| "JSON output is always better." | Use JSON only when it helps and will not expose secrets or unnecessary live data. |
