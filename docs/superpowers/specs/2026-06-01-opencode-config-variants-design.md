# OpenCode Config Variants Design

## Goal

Add an explicit `task config-switch` workflow that lets this repo switch the persisted OpenCode and Oh My OpenAgent runtime config between the current Z.AI Coding Plan setup and a new OpenAI ChatGPT subscription setup.

## Background

The repository currently ships one managed OpenCode config and one managed Oh My OpenAgent config:

- `bootstrap/config/opencode.json`
- `bootstrap/config/oh-my-openagent.jsonc`

The Docker image copies these into `/opt/opencode-defaults/*.managed`, and `scripts/docker-init.sh` seeds them into `/home/opencode/.config/opencode/` with version-marker logic. Existing runtime config is intentionally preserved unless the versioned managed seed path decides to re-seed.

Research findings:

- OpenCode supports OpenAI API-key auth through `OPENAI_API_KEY` or provider login.
- OpenCode supports ChatGPT Plus/Pro subscription auth through the built-in OpenAI OAuth plugin.
- ChatGPT subscription auth is not an API-key flow. It should be performed interactively/headlessly through OpenCode and then persisted in the mounted `OPENCODE_HOME_DIR`.
- OpenCode stores provider credentials under its data directory, separate from `opencode.json`.

## Requirements

- Keep the existing Z.AI Coding Plan config available as a named variant.
- Add an OpenAI ChatGPT subscription variant using only OpenAI GPT models.
- Provide `task config-switch -- <variant>` as the explicit user-facing switch.
- Do not have `task up` silently overwrite existing runtime config.
- Preserve the repo's non-destructive startup behavior.
- Keep auth secrets out of committed config files.
- Document first-time OpenAI ChatGPT login.
- Make OpenAI Oh My OpenAgent agent/category model choices match upstream OmO's OpenAI-only model-selection logic where possible.
- Add focused tests for variant validation and switch behavior.

## Non-Goals

- Do not automate ChatGPT OAuth token generation from `.env`.
- Do not store ChatGPT OAuth tokens in committed files.
- Do not add a new external dependency.
- Do not replace the existing Z.AI defaults with OpenAI defaults.
- Do not split the persisted home directory automatically by variant.

## Proposed Architecture

Add versioned bootstrap config variants under `bootstrap/config/variants/`:

```text
bootstrap/config/variants/
  zai-coding-plan/
    opencode.json
    oh-my-openagent.jsonc
  openai-chatgpt/
    opencode.json
    oh-my-openagent.jsonc
```

The top-level `bootstrap/config/opencode.json` and `bootstrap/config/oh-my-openagent.jsonc` remain the image default. They should match the `zai-coding-plan` variant so existing builds and first starts behave the same.

Add a small shell script, `scripts/config-switch.sh`, that:

1. Accepts one required variant argument.
2. Validates the variant name against directories under `bootstrap/config/variants/`.
3. Resolves `OPENCODE_HOME_DIR`, defaulting to `./data/home`.
4. Creates `${OPENCODE_HOME_DIR}/.config/opencode`.
5. Copies the selected variant's `opencode.json` and `oh-my-openagent.jsonc` into that runtime config directory.
6. Copies `bootstrap/config/AGENTS.md` if runtime `AGENTS.md` is missing.
7. Updates the runtime `.opencode-docker-config-version` from `bootstrap/config/.opencode-docker-config-version`.
8. Prints a concise success message and next auth step for the selected variant.

Add `task config-switch` to call this script:

```bash
task config-switch -- openai-chatgpt
task config-switch -- zai-coding-plan
```

This task is intentionally explicit because it overwrites the two managed runtime config files in the selected persisted home.

## Config Variant Details

### Z.AI Coding Plan

The Z.AI variant mirrors the current config:

- OpenCode provider: `zai-coding-plan`
- API key env: `OCD_ZHIPU_API_KEY`
- Optional Gemini provider for OmO visual/multimodal agents: `OCD_GEMINI_API_KEY`
- OmO model references continue to use `zai-coding-plan/...` plus Gemini only for visual categories.

### OpenAI ChatGPT

The OpenAI variant should use provider `openai` and OpenAI GPT model IDs from OpenCode's current model catalog.

The Oh My OpenAgent config must not use one generic OpenAI model everywhere. It should mirror OmO's upstream OpenAI-only model-selection output from `src/cli/model-fallback.ts`, `src/cli/openai-only-model-catalog.ts`, and the `single native provider uses OpenAI models when only OpenAI is available` snapshot. Current upstream OpenAI-only assignments are:

Agents:

- `sisyphus`: `openai/gpt-5.5`, variant `medium`
- `hephaestus`: `openai/gpt-5.5`, variant `medium`
- `prometheus`: `openai/gpt-5.5`, variant `high`
- `metis`: `openai/gpt-5.5`, variant `high`
- `oracle`: `openai/gpt-5.5`, variant `high`
- `momus`: `openai/gpt-5.5`, variant `xhigh`
- `atlas`: `openai/gpt-5.5`, variant `medium`
- `sisyphus-junior`: `openai/gpt-5.5`, variant `medium`
- `explore`: `openai/gpt-5.4-mini-fast`
- `librarian`: `openai/gpt-5.4-mini-fast`
- `multimodal-looker`: `openai/gpt-5.5`, variant `medium`, with fallback `openai/gpt-5-nano`

Categories:

- `artistry`: `openai/gpt-5.5`, variant `xhigh`
- `deep`: `openai/gpt-5.5`, variant `medium`
- `quick`: `openai/gpt-5.4-mini`
- `ultrabrain`: `openai/gpt-5.5`, variant `xhigh`
- `unspecified-high`: `openai/gpt-5.3-codex`, variant `medium` by default; if implementation intentionally models OmO's `isMaxPlan` path, use `openai/gpt-5.5`, variant `high`
- `unspecified-low`: `openai/gpt-5.3-codex`, variant `medium`
- `visual-engineering`: `openai/gpt-5.5`, variant `high`
- `writing`: `openai/gpt-5.5`, variant `medium`

Before implementation, re-check current Oh My OpenAgent source for this mapping. If upstream changed the OpenAI-only snapshot or generator, prefer the current upstream mapping over this frozen list and note the change in the implementation summary.

The OpenAI variant should set OmO concurrency for provider `openai` and the selected OpenAI models. It should not reference Z.AI, Gemini, Anthropic, OpenCode Go, Copilot, Vercel, or other model providers in the OpenAI variant's committed `oh-my-openagent.jsonc`.

Do not require `OPENAI_API_KEY` for the ChatGPT subscription variant. First-time auth is:

```bash
task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"
```

If OpenCode's current ChatGPT OAuth model catalog does not expose one of the upstream OmO model IDs, choose the closest OpenAI GPT model in the same role family and document the substitution. For example, use the newest available high-capability GPT model for `gpt-5.5` roles, the newest fast mini GPT model for `gpt-5.4-mini-fast` roles, and the newest Codex-oriented GPT model for `gpt-5.3-codex` roles.

## Data Flow

1. User builds or starts the stack normally. The image default remains Z.AI.
2. User runs `task config-switch -- openai-chatgpt`.
3. The script overwrites only the two managed runtime config files in `OPENCODE_HOME_DIR`.
4. User restarts the stack if it is already running.
5. User logs into OpenAI through OpenCode once.
6. OpenCode persists OAuth credentials in the mounted home.

Switching back to Z.AI uses:

```bash
task config-switch -- zai-coding-plan
```

## Error Handling

The switch script should fail with clear errors when:

- No variant is provided.
- The variant directory does not exist.
- Required files are missing in the variant directory.
- The target config directory cannot be created.
- A copy operation fails.

The script should not print credential values. It should only print variant names, file paths, and next commands.

## Testing

Add or update Bats tests to cover:

- `task --dry config-switch -- openai-chatgpt` calls the switch script.
- `scripts/config-switch.sh openai-chatgpt` writes both runtime config files to an isolated `OPENCODE_HOME_DIR`.
- Invalid variants fail with a useful error.
- The OpenAI variant does not reference `zai-coding-plan` or `google/gemini`.
- The OpenAI variant does not reference non-OpenAI model providers.
- The OpenAI variant's agent/category model map matches the current OmO OpenAI-only generator output, or a documented current-source substitution when OpenCode no longer exposes a listed model.
- The Z.AI variant still contains the current Z.AI provider references.
- Compose still validates for the default Z.AI path.

Run the smallest relevant checks:

```bash
task test-unit
task test-lint
OCD_ZHIPU_API_KEY=dummy docker compose -f docker-compose.yml config --quiet
```

If integration runtime behavior is touched during implementation, also run:

```bash
task test-integration
```

## Documentation

Update README and `.env.example` to document:

- The default Z.AI setup.
- The `task config-switch -- openai-chatgpt` workflow.
- The first-time OpenAI ChatGPT login command.
- That `OPENAI_API_KEY` is for API-key OpenAI usage, not required for ChatGPT subscription auth.
- That switching overwrites the selected home's managed runtime config files.

## Risks And Trade-Offs

- OpenAI ChatGPT OAuth model availability can change upstream. The implementation should verify model IDs against current OpenCode/model catalog before finalizing.
- Existing user edits to runtime `opencode.json` or `oh-my-openagent.jsonc` are overwritten by `task config-switch`. This is acceptable because the task is explicit and should document that behavior.
- ChatGPT OAuth cannot be fully preseeded from `.env` without handling sensitive OAuth token JSON. This design avoids that path.
- Keeping top-level bootstrap files as Z.AI defaults preserves existing behavior but duplicates the Z.AI config. Tests should catch drift where practical.

## Approval

This design was approved by the user with the explicit choice to follow the recommendation and add `task config-switch`.
