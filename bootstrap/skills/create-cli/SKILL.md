---
name: create-cli
description: >
  Use when designing or refactoring a non-trivial CLI interface that needs a
  complete, implementation-ready contract (command tree, flags/args, output
  modes, exit codes, safety rules, and config/env precedence) for consistent
  human and script usage.
---

# Create CLI

Design CLI surface area (syntax + behavior), human-first, script-friendly.

## Do This First

- Read `references/cli-guidelines.md` and apply it as the default rubric.
- Upstream/full guidelines: https://clig.dev/ (propose changes: https://github.com/cli-guidelines/cli-guidelines)
- Ask only the minimum clarifying questions needed to lock the interface.

## Clarify (fast)

Ask, then proceed with best-guess defaults if user is unsure:

- Command name + one-sentence purpose.
- Primary user: humans, scripts, or both.
- Input sources: args vs stdin; files vs URLs; secrets (never via flags).
- Output contract: human text, `--json`, `--plain`, exit codes.
- Interactivity: prompts allowed? need `--no-input`? confirmations for destructive ops?
- Config model: flags/env/config-file; precedence; XDG vs repo-local.
- Platform/runtime constraints: macOS/Linux/Windows; single binary vs runtime.

## Deliverables (what to output)

When designing a CLI, produce a compact spec the user can implement:

- Command tree + USAGE synopsis.
- Args/flags table (types, defaults, required/optional, examples).
- Subcommand semantics (what each does; idempotence; state changes).
- Output rules: stdout vs stderr; TTY detection; `--json`/`--plain`; `--quiet`/`--verbose`.
- Error + exit code map (top failure modes).
- Safety rules: `--dry-run`, confirmations, `--force`, `--no-input`.
- Config/env rules + precedence (flags > env > project config > user config > system).
- Shell completion story (if relevant): install/discoverability; generation command or bundled scripts.
- 5–10 example invocations (common flows; include piped/stdin examples).

## Default Conventions (unless user says otherwise)

- `-h/--help` always shows help and ignores other args.
- `--version` prints version to stdout.
- Primary data to stdout; diagnostics/errors to stderr.
- Add `--json` for machine output; consider `--plain` for stable line-based text.
- Prompts only when stdin is a TTY; `--no-input` disables prompts.
- Destructive operations: interactive confirmation + non-interactive requires `--force` or explicit `--confirm=...`.
- Respect `NO_COLOR`, `TERM=dumb`; provide `--no-color`.
- Handle Ctrl-C: exit fast; bounded cleanup; be crash-only when possible.

## Definition of Done (Self-Check)

Before finalizing a CLI spec, verify all checks pass:

- Response uses the required section order from `Required Output Template (strict)`.
- Includes at least one command tree and one `USAGE` synopsis.
- Includes args/flags with type, default, required/optional, and scope (global/subcommand).
- Defines stdout vs stderr behavior and machine-output modes (`--json` and/or `--plain`).
- Provides an explicit exit code map with at least `0`, `1`, and `2` (or justified equivalent).
- Defines safety behavior for destructive actions (`--dry-run`, confirmation, `--force`, `--no-input`).
- For secrets, requires stdin/file/secret-store input; never pass secrets via CLI flags.
- Defines config/env precedence exactly: flags > env > project config > user config > system.
- Includes at least 6 examples, covering stdin piping, `--json`, `--plain`, dry-run, destructive non-interactive flow, and one failure case with non-zero exit.

## Required Output Template (strict)

Use this exact section order in your answer. Keep it compact, but do not omit sections.
For very small CLIs, use the separate `create-cli-lite` skill instead of dropping required sections here.

### CLI spec skeleton

Fill all numbered sections below. You may omit only irrelevant sub-bullets inside a section.

1. **Name & one-liner**
   - `mycmd`:
   - Purpose:
2. **Command tree + USAGE**
   - `mycmd [global flags] <subcommand> [args]`
   - Subcommands:
3. **Arguments & flags tables**
   - Global flags table with columns: `Flag`, `Type`, `Default`, `Required`, `Scope`, `Notes`
   - Per-subcommand args/flags table(s) with the same columns
4. **Subcommand semantics**
   - What each subcommand does
   - Idempotence expectations
   - State changes / side effects
5. **I/O contract**
   - `stdout`:
   - `stderr`:
   - TTY behavior:
   - Machine output modes (`--json` / `--plain`):
6. **Error model + exit codes**
   - `0` success
   - `1` generic failure
   - `2` invalid usage (parse/validation)
   - Additional command-specific codes only if materially useful
7. **Safety model**
   - `--dry-run`
   - Confirmation behavior
   - `--force` / `--confirm=...`
   - `--no-input` behavior
8. **Config & environment**
   - Supported env vars
   - Config file location(s)
   - Precedence: flags > env > project config > user config > system
9. **Examples (minimum 6)**
   - Include at least:
   - one stdin/piped example
   - one `--json` example
   - one `--plain` example
   - one `--dry-run` example
   - one destructive non-interactive example with `--force`/`--confirm`
   - one failure example with expected non-zero exit

## Notes

- Prefer recommending a parsing library (language-specific) only when asked; otherwise keep this skill language-agnostic.
- If the request is “design parameters”, do not drift into implementation.
