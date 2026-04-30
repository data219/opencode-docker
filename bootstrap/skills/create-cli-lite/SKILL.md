---
name: create-cli-lite
description: >
  Use when designing a very small CLI (single command or 1-2 subcommands) where
  a concise but safe, script-friendly interface spec is needed without the full
  create-cli detail level.
---

# Create CLI Lite

Design small CLI surface areas quickly while preserving safety and scriptability.

## Do This First

- Read `references/cli-guidelines.md` and apply it as the default rubric.
- Ask only the minimum clarifying questions needed to lock the interface.
- If the scope becomes non-trivial, switch to `create-cli`.

## Clarify (fast)

Ask, then proceed with best-guess defaults if user is unsure:

- Command name + one-sentence purpose.
- Primary user: humans, scripts, or both.
- Input source: args, stdin, file, URL; secrets must use stdin/file/secret-store.
- Output mode: human text, `--json`, `--plain`, exit codes.
- Interactivity: prompts allowed? need `--no-input`? any destructive operations?

## Definition of Done (Self-Check)

Before finalizing, verify all checks pass:

- Uses all sections from `Required Output Template (minimal)` in order.
- Defines at least one usage line and one example for normal success flow.
- Defines stdout vs stderr and at least one machine output mode (`--json` or `--plain`).
- Defines minimum exit codes: `0` success, `1` failure, `2` usage/validation error.
- For destructive operations, defines `--dry-run`, confirmation behavior, and `--force`.
- For secrets, explicitly forbids passing them via CLI flags.
- Includes at least 4 examples, including one failure case with non-zero exit.

## Required Output Template (minimal)

Use this exact section order. Keep it compact.

1. **Name & purpose**
   - `mycmd`:
   - Purpose:
2. **USAGE + commands**
   - `mycmd [flags] [args]`
   - Subcommands (if any):
3. **Flags/args summary table**
   - Columns: `Option`, `Type`, `Default`, `Required`, `Notes`
4. **I/O + safety contract**
   - `stdout` vs `stderr`
   - `--json` / `--plain`
   - Prompting and `--no-input`
   - `--dry-run`, confirmation, `--force`
   - Secrets policy (stdin/file/secret-store only)
5. **Exit codes**
   - `0`, `1`, `2` (+ optional command-specific codes)
6. **Examples (minimum 4)**
   - Normal run
   - Machine-readable run
   - Dry-run or destructive-safe run
   - Failure run with expected non-zero exit

## Notes

- Keep this skill language-agnostic.
- If the user asks for a full contract (many subcommands, rich config model, completion story), switch to `create-cli`.
