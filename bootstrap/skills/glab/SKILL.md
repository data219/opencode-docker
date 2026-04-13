---
name: glab
description: Use when the user asks to work with GitLab from the terminal using `glab`, including authentication, issues, merge requests, CI/CD pipelines, releases, repositories, variables, tokens, Kubernetes agent workflows, Duo, or direct REST/GraphQL API calls.
---

# Glab

## Overview

Use `glab` as the default CLI for GitLab operations. Prefer native `glab` subcommands first, then use `glab api` when a capability is missing in dedicated subcommands.

## Baseline Workflow

1. Verify local command shape and version:

```bash
glab --version
glab --help
```

2. Verify authentication and target host:

```bash
glab auth status --all
git remote -v
```

3. Discover the exact subcommand before mutations:

```bash
glab <group> --help
glab <group> <subcommand> --help
```

4. Run read/list commands first, confirm target IDs/paths, then mutate.

5. If no native command exists, call the API directly:

```bash
glab api <endpoint>
glab api graphql -f query='query { currentUser { username } }'
```

## Authentication And Host Selection

Interactive login:

```bash
glab auth login
```

Non-interactive token login:

```bash
glab auth login --hostname <host> --stdin < token.txt
```

CI login with job token:

```bash
glab auth login --hostname "$CI_SERVER_HOST" --job-token "$CI_JOB_TOKEN"
```

Status checks:

```bash
glab auth status --all
glab auth status --hostname <host>
```

Rules:
- Prefer `--hostname` for multi-instance setups (GitLab.com + Self-Managed).
- Never print tokens in user-facing output.
- For non-current repos, pass `-R/--repo <group>/<project>`.

## Command Families

Primary collaboration:
- `glab issue ...` (issues, notes, board workflows)
- `glab mr ...` (create/view/update/approve/merge/rebase MRs)
- `glab repo ...` (project/repository lifecycle and metadata)

Delivery and operations:
- `glab ci ...`, `glab job ...`, `glab schedule ...` (pipelines, jobs, schedules)
- `glab release ...`, `glab changelog ...` (release workflows)
- `glab variable ...`, `glab token ...`, `glab securefile ...` (automation and secrets-related project config)

Account and access:
- `glab auth ...`, `glab config ...`
- `glab ssh-key ...`, `glab gpg-key ...`, `glab deploy-key ...`
- `glab user ...`, `glab label ...`, `glab milestone ...`, `glab iteration ...`

Advanced and platform features:
- `glab cluster ...` (GitLab Agent for Kubernetes)
- `glab duo ...` (Duo CLI features)
- `glab mcp ...` (MCP server, experimental)
- `glab stack ...`, `glab attestation ...`, `glab runner-controller ...` (experimental domains)

## Read-First Mutation Pattern

Use this sequence for any change:

```bash
# 1) Read/discover
glab <group> list ...
glab <group> view <id> ...

# 2) Mutate
glab <group> create ...
glab <group> update ...
glab <group> delete ...
```

Examples:

```bash
glab issue list -R group/project
glab issue update 123 --title "Updated title" -R group/project

glab mr view 456 -R group/project
glab mr merge 456 -R group/project
```

## API Fallback Pattern

Use `glab api` when subcommands do not expose needed fields or endpoints:

```bash
# REST
glab api projects/:fullpath/releases

# GraphQL
glab api graphql -f query='query { currentUser { username } }'
```

Useful flags:
- `--hostname` for explicit instance targeting.
- `--paginate` for full result sets.
- `--output ndjson` for stream-friendly processing.
- `-f/--raw-field/--field` for request parameters.

## Output And Safety Rules

- Prefer machine-friendly output for automation (`--output json|ndjson`, then `jq` if needed).
- When sharing results with users, include canonical GitLab URLs when available.
- Never expose secrets or raw credentials (tokens, masked variables, secure file contents).
- For destructive actions (`delete`, `revoke`, `rotate`, `transfer`, `merge`), confirm scope from a preceding read/list command.

## Sources

- [GitLab CLI Docs](https://docs.gitlab.com/cli/)
- [glab auth login](https://docs.gitlab.com/cli/auth/login/)
- [glab api](https://docs.gitlab.com/cli/api/)
- [glab ci](https://docs.gitlab.com/cli/ci/)
- [glab issue](https://docs.gitlab.com/cli/issue/)
- [glab mr](https://docs.gitlab.com/cli/mr/)
- [glab repo](https://docs.gitlab.com/cli/repo/)
- [glab release](https://docs.gitlab.com/cli/release/)
- [glab schedule](https://docs.gitlab.com/cli/schedule/)
- [glab token](https://docs.gitlab.com/cli/token/)
- [glab variable](https://docs.gitlab.com/cli/variable/)
