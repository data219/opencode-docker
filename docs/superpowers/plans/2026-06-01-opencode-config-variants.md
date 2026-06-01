# OpenCode Config Variants Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explicit Z.AI and OpenAI ChatGPT config variants plus `task config-switch -- <variant>` for switching the persisted OpenCode runtime config.

**Architecture:** Keep the existing top-level bootstrap config as the Z.AI default, add variant directories under `bootstrap/config/variants/`, and use a small shell script to overwrite only the selected home directory's managed runtime config files. OpenAI ChatGPT auth remains an OpenCode OAuth/device-login flow persisted in `OPENCODE_HOME_DIR`.

**Tech Stack:** Bash, Taskfile, Docker Compose, OpenCode JSON config, Oh My OpenAgent JSONC config, Bats tests, README/.env docs.

---

## File Structure

- Create `bootstrap/config/variants/zai-coding-plan/opencode.json`: copy of current Z.AI OpenCode config.
- Create `bootstrap/config/variants/zai-coding-plan/oh-my-openagent.jsonc`: copy of current Z.AI OmO config.
- Create `bootstrap/config/variants/openai-chatgpt/opencode.json`: OpenAI ChatGPT OpenCode config using built-in OpenAI provider and OmO plugin.
- Create `bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc`: OpenAI-only OmO config using upstream OmO OpenAI-only model mapping, with documented `gpt-5.4-mini-fast` to `gpt-5.4-mini` substitution because the current OpenCode/models.dev catalog does not expose `gpt-5.4-mini-fast`.
- Create `scripts/config-switch.sh`: runtime config switcher.
- Create `tests/unit/test_config_switch.bats`: focused switcher tests.
- Create `tests/lint/test_config_variants.bats`: static variant validation tests.
- Modify `Taskfile.yml`: add `config-switch`.
- Modify `README.md`: document variants, switch flow, and OpenAI auth.
- Modify `.env.example`: document variant/auth expectations without adding ChatGPT OAuth secrets.

---

### Task 1: Add Config Variant Files

**Files:**
- Create: `bootstrap/config/variants/zai-coding-plan/opencode.json`
- Create: `bootstrap/config/variants/zai-coding-plan/oh-my-openagent.jsonc`
- Create: `bootstrap/config/variants/openai-chatgpt/opencode.json`
- Create: `bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc`
- Test: `tests/lint/test_config_variants.bats`

- [ ] **Step 1: Write static variant tests first**

Create `tests/lint/test_config_variants.bats` with:

```bash
load ../test_helper

variant_file() {
  local variant="$1"
  local file="$2"
  printf 'bootstrap/config/variants/%s/%s' "$variant" "$file"
}

assert_file_exists() {
  local file="$1"
  [ -f "$file" ] || {
    echo "expected file to exist: $file" >&2
    return 1
  }
}

assert_json_valid() {
  local file="$1"
  jq empty "$file"
}

assert_jsonc_valid() {
  local file="$1"
  node -e '
    const fs = require("fs");
    const path = process.argv[1];
    const input = fs.readFileSync(path, "utf8")
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/(^|[^:])\/\/.*$/gm, "$1")
      .replace(/,\s*([}\]])/g, "$1");
    JSON.parse(input);
  ' "$file"
}

@test "config variants contain required files" {
  for variant in zai-coding-plan openai-chatgpt; do
    assert_file_exists "$(variant_file "$variant" opencode.json)"
    assert_file_exists "$(variant_file "$variant" oh-my-openagent.jsonc)"
  done
}

@test "variant OpenCode JSON files are valid JSON" {
  for variant in zai-coding-plan openai-chatgpt; do
    run assert_json_valid "$(variant_file "$variant" opencode.json)"
    assert_success
  done
}

@test "variant Oh My OpenAgent JSONC files are parseable" {
  command -v node >/dev/null 2>&1 || skip "node is required for JSONC validation"
  for variant in zai-coding-plan openai-chatgpt; do
    run assert_jsonc_valid "$(variant_file "$variant" oh-my-openagent.jsonc)"
    assert_success
  done
}

@test "zai-coding-plan variant mirrors current bootstrap config" {
  cmp -s bootstrap/config/opencode.json "$(variant_file zai-coding-plan opencode.json)"
  cmp -s bootstrap/config/oh-my-openagent.jsonc "$(variant_file zai-coding-plan oh-my-openagent.jsonc)"
}

@test "openai-chatgpt variant does not reference non-OpenAI model providers" {
  run rg -n 'zai-coding-plan|google/|anthropic/|github-copilot/|opencode-go/|vercel/|kimi-for-coding/|moonshotai|aihubmix|ollama-cloud|firmware|venice/' "$(variant_file openai-chatgpt oh-my-openagent.jsonc)"
  [ "$status" -eq 1 ]
}

@test "openai-chatgpt variant uses expected OmO OpenAI-only models with documented substitution" {
  file="$(variant_file openai-chatgpt oh-my-openagent.jsonc)"

  run rg -n 'openai/gpt-5\.5' "$file"
  assert_success

  run rg -n 'openai/gpt-5\.4-mini' "$file"
  assert_success

  run rg -n 'openai/gpt-5\.3-codex' "$file"
  assert_success

  run rg -n '"model": "openai/gpt-5\.4-mini-fast"' "$file"
  [ "$status" -eq 1 ]

  run rg -n 'gpt-5\.4-mini-fast is substituted with openai/gpt-5\.4-mini' "$file"
  assert_success
}

@test "openai-chatgpt variant keeps OpenCode config on OmO plugin without API key requirement" {
  run jq -e '.plugin | index("oh-my-openagent")' "$(variant_file openai-chatgpt opencode.json)"
  assert_success

  run rg -n 'OPENAI_API_KEY|apiKey' "$(variant_file openai-chatgpt opencode.json)"
  [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run lint test to verify it fails**

Run:

```bash
task test-lint
```

Expected: FAIL because `bootstrap/config/variants/...` files do not exist yet.

- [ ] **Step 3: Create Z.AI variant files from existing bootstrap config**

Run:

```bash
mkdir -p bootstrap/config/variants/zai-coding-plan bootstrap/config/variants/openai-chatgpt
cp bootstrap/config/opencode.json bootstrap/config/variants/zai-coding-plan/opencode.json
cp bootstrap/config/oh-my-openagent.jsonc bootstrap/config/variants/zai-coding-plan/oh-my-openagent.jsonc
```

- [ ] **Step 4: Create OpenAI ChatGPT OpenCode config**

Create `bootstrap/config/variants/openai-chatgpt/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "oh-my-openagent"
  ]
}
```

- [ ] **Step 5: Create OpenAI ChatGPT Oh My OpenAgent config**

Create `bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc`:

```jsonc
// opencode-docker-config:1
// OpenAI ChatGPT subscription variant.
// Auth is handled by OpenCode's built-in OpenAI OAuth/device-login flow, not by OPENAI_API_KEY.
// This model map follows Oh My OpenAgent's OpenAI-only generator output.
// OmO upstream currently emits openai/gpt-5.4-mini-fast for explore/librarian, but the current
// OpenCode/models.dev catalog does not expose that model id, so gpt-5.4-mini-fast is substituted with openai/gpt-5.4-mini.
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "openai/gpt-5.5",
      "variant": "medium"
    },
    "hephaestus": {
      "model": "openai/gpt-5.5",
      "variant": "medium",
      "prompt_append": "Follow established plans precisely. Ask for clarification when plans are ambiguous. Prefer small, testable changes. Use LSP and AST-grep aggressively."
    },
    "prometheus": {
      "model": "openai/gpt-5.5",
      "variant": "high",
      "prompt_append": "Always interview first. Validate scope before planning. Build exhaustive plans with milestones, risks, and contingencies. Max 2 parallel background tasks."
    },
    "metis": {
      "model": "openai/gpt-5.5",
      "variant": "high",
      "prompt_append": "Critically evaluate plans. Identify gaps, risks, and improvements. Be thorough."
    },
    "oracle": {
      "model": "openai/gpt-5.5",
      "variant": "high"
    },
    "momus": {
      "model": "openai/gpt-5.5",
      "variant": "xhigh",
      "prompt_append": "Challenge all assumptions in plans. Look for edge cases, failure modes, and overlooked requirements."
    },
    "atlas": {
      "model": "openai/gpt-5.5",
      "variant": "medium"
    },
    "sisyphus-junior": {
      "model": "openai/gpt-5.5",
      "variant": "medium"
    },
    "explore": {
      "model": "openai/gpt-5.4-mini",
      "prompt_append": "Prefer searching official documentation and library sources over general web search."
    },
    "librarian": {
      "model": "openai/gpt-5.4-mini",
      "prompt_append": "Focus on finding authoritative sources. Cross-reference results when possible. Keep research brief and decision-oriented: return only the facts needed for the current task, cite sources, and avoid exhaustive result dumps or broad background unless explicitly requested. Prefer a short answer with 3-5 high-signal bullets over long summaries."
    },
    "multimodal-looker": {
      "model": "openai/gpt-5.5",
      "variant": "medium",
      "fallback_models": [
        "openai/gpt-5-nano"
      ]
    }
  },
  "categories": {
    "ultrabrain": {
      "model": "openai/gpt-5.5",
      "variant": "xhigh"
    },
    "visual-engineering": {
      "model": "openai/gpt-5.5",
      "variant": "high"
    },
    "unspecified-high": {
      "model": "openai/gpt-5.3-codex",
      "variant": "medium"
    },
    "deep": {
      "model": "openai/gpt-5.5",
      "variant": "medium"
    },
    "writing": {
      "model": "openai/gpt-5.5",
      "variant": "medium"
    },
    "quick": {
      "model": "openai/gpt-5.4-mini"
    },
    "unspecified-low": {
      "model": "openai/gpt-5.3-codex",
      "variant": "medium"
    },
    "artistry": {
      "model": "openai/gpt-5.5",
      "variant": "xhigh"
    }
  },
  "runtime_fallback": {
    "enabled": true,
    "retry_on_errors": [
      429,
      503,
      529
    ],
    "max_fallback_attempts": 3,
    "cooldown_seconds": 60
  },
  "default_mode": {
    "ultrawork": true,
    "ralph_loop": true
  },
  "background_task": {
    "staleTimeoutMs": 5400000,
    "messageStalenessTimeoutMs": 7200000,
    "taskTtlMs": 7200000,
    "sessionGoneTimeoutMs": 180000,
    "providerConcurrency": {
      "openai": 3
    },
    "modelConcurrency": {
      "openai/gpt-5.5": 2,
      "openai/gpt-5.4-mini": 2,
      "openai/gpt-5.3-codex": 2,
      "openai/gpt-5-nano": 2
    }
  },
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
    "max_members": 8,
    "tmux_visualization": false
  },
  "browser_automation_engine": {
    "provider": "agent-browser"
  },
  "git_master": {
    "commit_footer": true,
    "include_co_authored_by": true,
    "git_env_prefix": "GIT_"
  },
  "sisyphus_agent": {
    "planner_enabled": true,
    "replace_plan": true
  },
  "hashline_edit": true,
  "experimental": {
    "aggressive_truncation": false,
    "task_system": true,
    "auto_resume": true
  }
}
```

- [ ] **Step 6: Run lint tests**

Run:

```bash
task test-lint
```

Expected: PASS for `tests/lint/test_config_variants.bats`; existing lint tests should continue passing.

- [ ] **Step 7: Commit Task 1**

Run:

```bash
git add bootstrap/config/variants tests/lint/test_config_variants.bats
git commit -m "feat: add opencode config variants"
```

---

### Task 2: Add Config Switch Script

**Files:**
- Create: `scripts/config-switch.sh`
- Create: `tests/unit/test_config_switch.bats`

- [ ] **Step 1: Write switcher unit tests first**

Create `tests/unit/test_config_switch.bats`:

```bash
load ../test_helper

setup() {
  TEST_HOME_DIR="$(mktemp -d "${PWD}/.test-config-switch-home.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_HOME_DIR"
}

config_dir() {
  printf '%s/.config/opencode' "$TEST_HOME_DIR"
}

@test "config-switch requires a variant" {
  run scripts/config-switch.sh

  assert_failure
  assert_output --partial "Usage: scripts/config-switch.sh <variant>"
}

@test "config-switch rejects unknown variants" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh missing-variant

  assert_failure
  assert_output --partial "ERROR: unknown config variant: missing-variant"
  assert_output --partial "Available variants:"
}

@test "config-switch writes openai-chatgpt runtime config to OPENCODE_HOME_DIR" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  assert_output --partial "Switched OpenCode config variant to openai-chatgpt"
  assert_output --partial "task opencode -- auth login --provider openai --method"

  [ -f "$(config_dir)/opencode.json" ]
  [ -f "$(config_dir)/oh-my-openagent.jsonc" ]
  [ -f "$(config_dir)/AGENTS.md" ]
  [ -f "$(config_dir)/.opencode-docker-config-version" ]

  cmp -s bootstrap/config/variants/openai-chatgpt/opencode.json "$(config_dir)/opencode.json"
  cmp -s bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc "$(config_dir)/oh-my-openagent.jsonc"
}

@test "config-switch writes zai-coding-plan runtime config to OPENCODE_HOME_DIR" {
  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh zai-coding-plan

  assert_success
  assert_output --partial "Switched OpenCode config variant to zai-coding-plan"
  assert_output --partial "Ensure OCD_ZHIPU_API_KEY is set"

  cmp -s bootstrap/config/variants/zai-coding-plan/opencode.json "$(config_dir)/opencode.json"
  cmp -s bootstrap/config/variants/zai-coding-plan/oh-my-openagent.jsonc "$(config_dir)/oh-my-openagent.jsonc"
}

@test "config-switch preserves existing runtime AGENTS.md" {
  mkdir -p "$(config_dir)"
  printf '%s\n' '# user custom agents' > "$(config_dir)/AGENTS.md"

  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  assert_equal "$(cat "$(config_dir)/AGENTS.md")" "# user custom agents"
}

@test "config-switch overwrites only managed runtime config files" {
  mkdir -p "$(config_dir)"
  printf '%s\n' 'keep me' > "$(config_dir)/custom.txt"
  printf '%s\n' '{"old":true}' > "$(config_dir)/opencode.json"

  run env OPENCODE_HOME_DIR="$TEST_HOME_DIR" scripts/config-switch.sh openai-chatgpt

  assert_success
  [ -f "$(config_dir)/custom.txt" ]
  assert_equal "$(cat "$(config_dir)/custom.txt")" "keep me"
  cmp -s bootstrap/config/variants/openai-chatgpt/opencode.json "$(config_dir)/opencode.json"
}
```

- [ ] **Step 2: Run unit test to verify it fails**

Run:

```bash
task test-unit
```

Expected: FAIL because `scripts/config-switch.sh` does not exist.

- [ ] **Step 3: Create config switch script**

Create `scripts/config-switch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: scripts/config-switch.sh <variant>" >&2
  echo "Available variants:" >&2
  list_variants >&2
}

list_variants() {
  local variant_dir
  if [ ! -d "bootstrap/config/variants" ]; then
    return 0
  fi
  for variant_dir in bootstrap/config/variants/*; do
    [ -d "$variant_dir" ] || continue
    printf '  %s\n' "$(basename "$variant_dir")"
  done
}

copy_required_file() {
  local source="$1"
  local target="$2"
  if [ ! -f "$source" ]; then
    echo "ERROR: required variant file missing: $source" >&2
    exit 1
  fi
  cp -a -- "$source" "$target"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

VARIANT="$1"
VARIANT_DIR="bootstrap/config/variants/$VARIANT"

if [ ! -d "$VARIANT_DIR" ]; then
  echo "ERROR: unknown config variant: $VARIANT" >&2
  echo "Available variants:" >&2
  list_variants >&2
  exit 1
fi

OPENCODE_HOME_DIR="${OPENCODE_HOME_DIR:-./data/home}"
CONFIG_DIR="$OPENCODE_HOME_DIR/.config/opencode"

mkdir -p "$CONFIG_DIR"

copy_required_file "$VARIANT_DIR/opencode.json" "$CONFIG_DIR/opencode.json"
copy_required_file "$VARIANT_DIR/oh-my-openagent.jsonc" "$CONFIG_DIR/oh-my-openagent.jsonc"

if [ ! -f "$CONFIG_DIR/AGENTS.md" ] && [ -f "bootstrap/config/AGENTS.md" ]; then
  cp -a -- "bootstrap/config/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

if [ -f "bootstrap/config/.opencode-docker-config-version" ]; then
  cp -a -- "bootstrap/config/.opencode-docker-config-version" "$CONFIG_DIR/.opencode-docker-config-version"
fi

echo "Switched OpenCode config variant to $VARIANT"
echo "Runtime config: $CONFIG_DIR"

case "$VARIANT" in
  openai-chatgpt)
    echo "Next auth step, if this home has not logged in yet:"
    echo '  task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"'
    ;;
  zai-coding-plan)
    echo "Ensure OCD_ZHIPU_API_KEY is set before starting the stack."
    ;;
esac
```

- [ ] **Step 4: Make script executable**

Run:

```bash
chmod +x scripts/config-switch.sh
```

- [ ] **Step 5: Run unit tests**

Run:

```bash
task test-unit
```

Expected: PASS for `tests/unit/test_config_switch.bats`; existing unit tests should continue passing.

- [ ] **Step 6: Commit Task 2**

Run:

```bash
git add scripts/config-switch.sh tests/unit/test_config_switch.bats
git commit -m "feat: add config switch script"
```

---

### Task 3: Wire Taskfile Command

**Files:**
- Modify: `Taskfile.yml`
- Modify: `tests/lint/test_compose.bats`

- [ ] **Step 1: Add Taskfile dry-run test first**

Append to `tests/lint/test_compose.bats`:

```bash
@test "task config-switch calls switch script with CLI args" {
  command -v task > /dev/null 2>&1 || skip "task not available"

  run task --dry config-switch -- openai-chatgpt

  [ "$status" -eq 0 ]
  [[ "$output" == *"scripts/config-switch.sh openai-chatgpt"* ]]
}
```

- [ ] **Step 2: Run lint test to verify it fails**

Run:

```bash
task test-lint
```

Expected: FAIL because `config-switch` task is not defined.

- [ ] **Step 3: Add Taskfile task**

Modify `Taskfile.yml` after `migrate-env`:

```yaml
  config-switch:
    desc: Switch the persisted OpenCode config variant (args: zai-coding-plan or openai-chatgpt)
    cmds:
      - "scripts/config-switch.sh {{.CLI_ARGS}}"
```

- [ ] **Step 4: Run lint tests**

Run:

```bash
task test-lint
```

Expected: PASS.

- [ ] **Step 5: Commit Task 3**

Run:

```bash
git add Taskfile.yml tests/lint/test_compose.bats
git commit -m "feat: add config-switch task"
```

---

### Task 4: Update Documentation And Env Example

**Files:**
- Modify: `README.md`
- Modify: `.env.example`

- [ ] **Step 1: Update `.env.example` provider comments**

Modify the top runtime API-key block in `.env.example` to:

```env
# --- Runtime Environment Variables ---

# Config variant:
# - zai-coding-plan is the default image/bootstrap config.
# - openai-chatgpt is selected with: task config-switch -- openai-chatgpt
# This is intentionally a task, not an automatic startup toggle, because it
# overwrites the selected OPENCODE_HOME_DIR runtime config files.

# Z.AI Coding Plan API key (required for the default zai-coding-plan variant)
# Get your key from: https://open.bigmodel.cn/
OCD_ZHIPU_API_KEY=

# Google AI Studio API key for Gemini vision model in the Z.AI variant
# Get your key at: https://aistudio.google.com/apikey
OCD_GEMINI_API_KEY=

# OpenAI ChatGPT subscription auth is not configured here.
# For the openai-chatgpt variant, switch config and then log in once:
#   task config-switch -- openai-chatgpt
#   task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"
# OpenAI API-key usage is separate from ChatGPT subscription auth.
# OPENAI_API_KEY=
```

- [ ] **Step 2: Update README quick start and configuration sections**

In `README.md`, update the quick-start prerequisite text so Z.AI is clearly the default:

```markdown
- A Z.AI Coding Plan API key for the default GLM provider
- Optional: a Google AI Studio API key for the Gemini vision model used by the default Z.AI OmO visual tasks
- Optional: a ChatGPT Plus/Pro subscription for the `openai-chatgpt` config variant
```

Add a subsection under `## Configuration`:

````markdown
### Config variants

The image default is `zai-coding-plan`, which matches the bootstrap config in `bootstrap/config/`.

Use the explicit switch task to overwrite the selected persisted home config:

```bash
task config-switch -- openai-chatgpt
task config-switch -- zai-coding-plan
```

The task writes only these managed runtime files under `${OPENCODE_HOME_DIR:-./data/home}/.config/opencode/`:

- `opencode.json`
- `oh-my-openagent.jsonc`
- `.opencode-docker-config-version`

It seeds `AGENTS.md` only when it is missing.

For the OpenAI ChatGPT subscription variant, log in once after switching and starting the stack:

```bash
task up
task opencode -- auth login --provider openai --method "ChatGPT Pro/Plus (headless)"
```

OpenAI ChatGPT subscription auth is an OpenCode OAuth/device-login flow. It is not configured through `.env` and does not require `OPENAI_API_KEY`. The login is persisted in `OPENCODE_HOME_DIR`.
````

Update the model providers section to mention both variants:

```markdown
The seeded default config defines the `zai-coding-plan` provider via `OCD_ZHIPU_API_KEY` and the optional Google provider via `OCD_GEMINI_API_KEY`.

The `openai-chatgpt` variant uses OpenCode's built-in OpenAI provider and Oh My OpenAgent's OpenAI-only model map. It uses ChatGPT Plus/Pro OAuth login, not an API key.
```

- [ ] **Step 3: Run documentation grep checks**

Run:

```bash
rg -n "config-switch|openai-chatgpt|ChatGPT Pro/Plus|OPENAI_API_KEY|OCD_ZHIPU_API_KEY" README.md .env.example
```

Expected: Output includes the new workflow and clearly states that `OPENAI_API_KEY` is not required for ChatGPT subscription auth.

- [ ] **Step 4: Commit Task 4**

Run:

```bash
git add README.md .env.example
git commit -m "docs: document config variants"
```

---

### Task 5: Full Verification

**Files:**
- No planned edits.

- [ ] **Step 1: Run unit tests**

Run:

```bash
task test-unit
```

Expected: PASS.

- [ ] **Step 2: Run lint tests**

Run:

```bash
task test-lint
```

Expected: PASS.

- [ ] **Step 3: Render Compose config with default required env**

Run:

```bash
OCD_ZHIPU_API_KEY=dummy docker compose -f docker-compose.yml config --quiet
```

Expected: exit 0.

- [ ] **Step 4: Smoke-test switch script manually with a temporary home**

Run:

```bash
tmp_home="$(mktemp -d "$PWD/.tmp-config-switch.XXXXXX")"
OPENCODE_HOME_DIR="$tmp_home" scripts/config-switch.sh openai-chatgpt
test -f "$tmp_home/.config/opencode/opencode.json"
test -f "$tmp_home/.config/opencode/oh-my-openagent.jsonc"
rm -rf "$tmp_home"
```

Expected: exit 0 and success message from `scripts/config-switch.sh`.

- [ ] **Step 5: Check git diff and whitespace**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors. `git status --short` should show no uncommitted changes after all task commits.
