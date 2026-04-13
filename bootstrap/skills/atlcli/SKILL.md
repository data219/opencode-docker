---
name: atlcli
description: Use when the user asks to work with Atlassian Jira or Confluence from the terminal using atlcli, including authentication profiles, Jira issue/sprint/worklog operations, Confluence wiki/docs sync, inline comments, troubleshooting, and JSON output for automation.
---

# AtlCLI

Use this skill for Jira/Confluence CLI tasks with `atlcli`.

## Source Of Truth

- Run `atlcli --version` first.
- In `v0.14.x`, Confluence namespace is `atlcli wiki ...`.
- For executable command syntax, local `atlcli <group> --help` is authoritative.
- Use [COMMAND-REFERENCE.md](./COMMAND-REFERENCE.md) for discovery/routing only.
- If local help and appendix differ, stop and ask before any mutation.

## Quick Routing

- Issues/search/boards/sprints/worklogs: `jira`
- Pages/spaces/comments/docs sync: `wiki`
- Auth/profile/config/log/plugin health: root groups (`auth`, `config`, `doctor`, `log`, `plugin`)
- Full command list: [COMMAND-REFERENCE.md](./COMMAND-REFERENCE.md)

## Safety Gates (Required)

For any non-read-only command (for example `create`, `update`, `delete`, `transition`, `bulk`, `push`, `resolve`, `assign`, `comment`, `attach`, `link`, `start/stop`, `add/remove`, `import/export`, `apply`, `share`, `set/unset`, `clear`, `install/enable/disable`):
1. Run read-first preview when an equivalent read exists (`get/list/search --json`); otherwise use `diff/status/check --strict` or a dry-run command.
2. Scope check: explicit key/ID/filter and impact count.
3. Use explicit `--profile <name>`.
4. High-impact operations always require explicit user ACK in this thread before execution.
5. Post-write verify via read command and include resulting URL/ID.
6. If no preview/dry-run/verification path exists, stop and ask for explicit risk acceptance before proceeding.

High-impact definition:
- Any command with `delete`, `bulk`, `archive`, `restore`, `push`, `resolve`, `--fix`, `update`, `import`, `export`, `install`, `enable`, `disable`, `switch`, `logout`, `login`, or wildcard-wide filters (for example broad JQL/CQL without tight key/ID scope).

## Security Guardrails

- Never print tokens.
- Prefer secret managers/CI secrets over inline `export ...=<token>`.
- Use least-privilege profiles (separate automation profile per tenant/project/space).
- After ephemeral env-token use: `unset ATLCLI_API_TOKEN`.
- Treat `config list` and `log` output as sensitive; redact before sharing.
- For sensitive or mutating flows, add `--no-log` where supported.

## Inline Comments (Confluence)

```bash
atlcli --profile work wiki page comments add-inline --id 12345 --selection "target text" "Please clarify"
atlcli --profile work wiki page comments add-inline --id 12345 --selection "target text" --match-index 2 "Third match"
atlcli --profile work wiki page comments list --id 12345 --inline
atlcli --profile work wiki page comments resolve --comment 67890 --type inline
```

Rules:
- Pull/get fresh content before selection-based comments.
- If selection is repeated, set `--match-index` intentionally.
- Use `--type inline` when resolving/deleting inline threads.

## Script Paths

```bash
SKILL_DIR="/home/jan/.dotfiles/.agents/skills/atlcli"
$SKILL_DIR/scripts/atl_md_links.sh --help
$SKILL_DIR/scripts/safe_wiki_sync.sh ./docs --profile work
```

## Verification Evidence (RED/GREEN/REFACTOR)

- RED:
  - [artifacts/red-scenario-inline-comments.md](./artifacts/red-scenario-inline-comments.md)
  - [artifacts/red-scenario-destructive-safety.md](./artifacts/red-scenario-destructive-safety.md)
- GREEN:
  - [artifacts/green-scenario-inline-comments.md](./artifacts/green-scenario-inline-comments.md)
  - [artifacts/green-scenario-destructive-safety.md](./artifacts/green-scenario-destructive-safety.md)
- REFACTOR:
  - [artifacts/refactor-loopholes.md](./artifacts/refactor-loopholes.md)

## Sources

- [CLI Commands](https://atlcli.sh/reference/cli-commands)
- [Confluence Comments](https://atlcli.sh/confluence/comments)
- [Environment](https://atlcli.sh/reference/environment)
- [Bundled Command Reference](./COMMAND-REFERENCE.md)
