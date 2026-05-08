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

## Docker-First Workflow

When a project has Docker or Docker Compose setup, run tests and project commands inside containers.

Check command sources in this order unless project documentation says otherwise:

1. Taskfile
2. Makefile
3. Docker Compose

Prefer `docker compose exec` for running services and `docker compose run --rm` for one-off commands.

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
