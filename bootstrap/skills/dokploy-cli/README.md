# dokploy-cli-skill

`data219/dokploy-cli-skill` is a public skill repository for AI agents that work with Dokploy. It teaches agents to prefer the installed `dokploy` CLI for Dokploy work, to treat output as potentially sensitive, and to ask before risky actions.

## Purpose

Use this repository when you want an agent harness to load a concise Dokploy safety policy before it helps with Dokploy operations. The skill is meant for local agent use, where the user already controls whether the Dokploy CLI is installed and authenticated.

## Non-goals

1. This is not a Dokploy API client, SDK wrapper, or direct API fallback tool.
2. It does not install or configure Dokploy itself.
3. It does not document every Dokploy command.
4. It does not make every agent harness a first-class supported target in v1.
5. It does not require CI users or public repo readers to have Dokploy credentials.

## Safety summary

Agents using this skill should:

1. Prefer `dokploy` CLI commands when the CLI is installed and can satisfy the request.
2. Treat read-only output as sensitive if it can reveal server names, domains, users, IDs, logs, or configuration.
3. Do not print tokens, secrets, private URLs, local config contents, or environment values.
4. Ask for explicit approval before any mutating operation, such as create, update, delete, deploy, restart, stop, cancel, rollback, or save.
5. Ask for explicit approval before using a direct Dokploy API fallback, and explain why the CLI is unavailable or insufficient.
6. Keep examples public-safe. Use placeholders only, never real credentials or live server URLs.

## v1 harness support

| Harness | v1 status | How to use |
| --- | --- | --- |
| OpenCode | Supported | Install `SKILL.md` into the OpenCode skills directory. |
| Codex/OpenAI-style agents | Supported | Use `agents/openai.yaml` as metadata and point the agent to `SKILL.md`. |
| Other harnesses | Generic, adaptable | Adapt or copy `SKILL.md` into the harness format. Do not assume native support unless you add and test harness-specific metadata. |

## Prerequisites

1. A shell with `wget`, `tar`, and `mkdir`.
2. An agent harness that can read a local skill or instruction file.
3. Optional for local smoke checks: the Dokploy CLI available as `dokploy` on `PATH`.

Do not inspect local Dokploy auth files just to install this skill. If the CLI is already configured, use read-only help commands for verification.

## Install from GitHub tarball

The commands below install the repository from the GitHub archive. They use the public repo name and do not need Dokploy credentials.

```sh
SKILL_DIR="$HOME/.config/opencode/skills/dokploy-cli"
mkdir -p "$SKILL_DIR"
wget -qO- "https://github.com/data219/dokploy-cli-skill/archive/refs/heads/main.tar.gz" | tar -xz --strip-components=1 -C "$SKILL_DIR"
test -f "$SKILL_DIR/SKILL.md"
```

If your default branch is not `main`, change the archive path to the branch or tag you want to install.

## OpenCode path

For OpenCode, install to a skill directory under:

```text
~/.config/opencode/skills/dokploy-cli/
```

After installation, verify the skill file exists:

```sh
test -f "$HOME/.config/opencode/skills/dokploy-cli/SKILL.md"
```

Then ask OpenCode to use the `dokploy-cli` skill for Dokploy work.

## Codex and OpenAI-style agents

Codex and OpenAI-style harnesses should read `agents/openai.yaml` and use it as a small metadata pointer to the normative instructions in `SKILL.md`. The YAML is intentionally short, so the full safety policy stays in one place.

Recommended setup:

1. Copy this repository into a local instructions or agent-assets directory.
2. Configure the agent profile to include `agents/openai.yaml`.
3. Make sure the profile tells the agent to read `SKILL.md` before Dokploy work.
4. Keep `SKILL.md` as the source of truth, rather than duplicating the whole policy in a prompt.

## Generic harness adaptation

For other harnesses, adapt or copy `SKILL.md` into the harness instruction format. This repo does not include tested native metadata for Claude, Cursor, Windsurf, or other harnesses yet. Keep these rules intact:

1. Prefer the `dokploy` CLI over direct API calls when available.
2. Require explicit approval for mutating operations.
3. Require explicit approval for direct API fallback.
4. Redact sensitive output and do not print credentials.
5. Use read-only verification commands by default.

If a harness needs metadata, add a small pointer file that references `SKILL.md`. Do not claim native support until the metadata has been tested in that harness.

## Read-only verification commands

These checks are safe for local installation and public CI because they do not require Dokploy credentials and do not query live server data.

```sh
test -f README.md
test -f SKILL.md
test -f agents/openai.yaml
python - <<'PY'
from pathlib import Path
text = Path('README.md').read_text()
for phrase in ['OpenCode', 'Codex', 'dokploy-cli-skill', 'tar.gz', 'dokploy --help', 'do not print', 'explicit approval']:
    assert phrase in text, phrase
PY
```

If the Dokploy CLI is installed, you can also run help-only checks:

```sh
dokploy --help
dokploy --version
```

Do not use create, update, delete, deploy, restart, stop, cancel, rollback, or other state-changing commands as verification.

## Safe prompts

Examples that should stay read-only:

1. "Use the Dokploy CLI help output to explain what command group manages projects. Do not print credentials."
2. "Check whether `dokploy --help` is available and summarize the command groups without querying live server data."
3. "Review `SKILL.md` and tell me what approvals are needed before a deployment action."

## Requests that require approval

These requests need explicit approval before the agent acts:

1. "Deploy this application."
2. "Restart the service."
3. "Delete the test project."
4. "Call the Dokploy API directly because the CLI command failed."
5. "Show me live server settings or logs."

Approval should be specific to the action. A vague statement like "do what is needed" is not enough for a mutating operation or direct API fallback.

## Update or refresh

To refresh an installed copy, rerun the tarball install command for the target branch or tag. For a Git checkout, use normal Git update commands in your local copy, then rerun the read-only verification commands.

When upstream Dokploy CLI behavior changes, refresh the command notes by checking the current CLI help output and upstream docs. Keep `SKILL.md` as the policy source of truth and keep `COMMAND-REFERENCE.md` as a non-normative appendix.

## Contributions

Contributions should keep this repository safe for a public GitHub repo:

1. Do not add real tokens, private URLs, local config contents, or direct Dokploy API setup examples.
2. Do not require CI secrets or live Dokploy credentials.
3. Prefer small docs and validation changes that are easy to audit.
4. Update tests or validation scripts when safety wording changes.
5. Keep examples copyable with placeholders only.
