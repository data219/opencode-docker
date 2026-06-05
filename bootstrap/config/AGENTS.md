# Global OpenCode Instructions

These instructions apply to every OpenCode session in this user environment.
Repository-local `AGENTS.md` files may add more specific project rules.
If global and repository-local instructions conflict, ask which rule to follow.

## General Working Style

Prefer minimal, targeted changes. Preserve existing conventions, structure, and naming unless the user asks for a broader change.

Fix root causes when practical. Avoid cosmetic-only changes unless requested.

Do not make destructive changes, including destructive Git commands, unless the user explicitly asks for them.

If the worktree contains changes you did not make, do not revert them. Work around them or ask when they block the task.

## Verification

Run the smallest relevant verification that proves the change.

If tests or checks cannot run, say so clearly and explain why.

Do not claim a fix is complete unless the relevant output was checked.

## Background Tasks

Default `background_output` reads are cursor-based and return only new output since the last default read for that task. If you need to re-read a completed task, call `background_output` with `full_session=true`; use `since_message_id` only when you intentionally want explicit incremental reads.

## Docker-First Workflow

When a project has Docker or Docker Compose setup, run tests and project commands inside containers.

Check command sources in this order unless project documentation says otherwise:

1. Taskfile
2. Makefile
3. Docker Compose

Prefer `docker compose exec` for running services and `docker compose run --rm` for one-off commands.

## Available Tools

The Docker Compose stack includes these command-line tools:

- `gh`: GitHub CLI for repositories, issues, pull requests, and Actions checks.
- `glab`: GitLab CLI for projects, merge requests, issues, and pipelines.
- `cntb`: Contabo CLI for cloud resource inspection and operations.
- `atlcli`: Atlassian CLI for Jira and Confluence workflows.
- `dokploy`: Dokploy CLI for remote Dokploy server management.
- `cloudflared`: Cloudflare tunnel CLI for exposing local services when configured.
- `docker`: Docker client for image, container, network, and volume operations.
- `docker compose`: Compose plugin for managing multi-container local stacks.
- `make`: Build automation tool for Makefile-driven project tasks.
- `ansible`: Automation CLI for playbooks, inventories, and provisioning tasks.
- `terraform`: Infrastructure-as-code CLI for planning and applying Terraform modules.
- `kubectl`: Kubernetes CLI for inspecting and managing clusters and workloads.
- `helm`: Kubernetes package manager for chart rendering, installs, and upgrades.
- `jq`: JSON processor for filtering, transforming, and validating JSON data.
- `yq`: YAML, JSON, and XML processor for config inspection and edits.
- `rg`: ripgrep CLI for fast recursive text search.
- `shellcheck`: Static analyzer for shell scripts.
- `git`: Version control CLI for repository history, branches, diffs, and commits.
- `zsh`: Interactive shell for user dotfiles and shell customization.
- `curl`: HTTP client for API calls, downloads, and network checks.
- `wget`: HTTP client for file downloads and simple network checks.

## Available Programming Languages

The Docker Compose stack always includes these programming language runtimes and package tools:

- Node.js: JavaScript and TypeScript runtime for npm-based projects and CLIs.
- Python: Python 3 runtime, `pip`, virtual environments, and `pyenv` for Python version management.
- Go: Go toolchain plus `gvm` support for Go version management.
- PHP: PHP 8.4 CLI with common extensions for PHP and Symfony-style projects.
- Composer: PHP dependency manager.
- Shell: Bash and POSIX shell tooling for scripts and automation.

Optional build-time language runtimes may also be installed. Check whether the command exists before relying on one:

- Java: available only when the image was built with `INSTALL_JAVA=true`.
- Ruby: available only when the image was built with `INSTALL_RUBY=true`.
- Swift: available only when the image was built with `INSTALL_SWIFT=true`.
- Elixir/Erlang: available only when the image was built with `INSTALL_ELIXIR=true`.
- nvm-managed Node.js: available only when the image was built with `INSTALL_NVM=true`.
- Rust: available only when the image was built with `INSTALL_RUST=true`.

## Git

Use conventional commits for normal commits.

Do not rewrite history, reset branches, or force-push unless explicitly requested.

## Git Branch Creation

Before creating a new Git branch, always start from the latest default branch.

Required workflow:

1. Detect the repository default branch, usually `main` or `master`.
2. Run `git fetch --prune origin`.
3. Switch to the default branch.
4. Update it with `git pull --ff-only`.
5. Create the new branch from that updated default branch.

Never create a new feature branch from the currently checked-out feature branch unless the user explicitly asks for a stacked branch.

Use this command pattern unless the repository documents a different workflow:

```sh
default_branch="$(git symbolic-ref refs/remotes/origin/HEAD --short | sed 's#^origin/##')"
git fetch --prune origin
git switch "$default_branch"
git pull --ff-only
git switch -c "<new-branch-name>"
```

## Security

Never print secrets, tokens, private keys, or credentials.

Redact sensitive values in logs and examples.

Call out authentication, authorization, input validation, and data exposure risks when relevant.
