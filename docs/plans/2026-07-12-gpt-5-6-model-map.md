# GPT-5.6 Model Map Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace every active GPT-5.5 reference in the OpenAI ChatGPT bootstrap variant with the appropriate GPT-5.6 Sol, Terra, or Luna model while retaining compatible reasoning efforts.

**Architecture:** Keep the existing Oh My OpenAgent role structure and use explicit OpenCode model IDs. Replace every active GPT-5.5 reference: Sol serves the primary orchestrators and quality-critical roles, Terra serves balanced work, and Luna serves economical research fallbacks. Keep reasoning variants at or below `xhigh`, because the pinned OpenCode release does not reliably expose `max` through this configuration path.

**Tech Stack:** JSONC bootstrap configuration, Bats, Docker Compose bootstrap seeding.

---

### Task 1: Define the GPT-5.6 model-map contract

**Files:**
- Modify: `tests/lint/test_config_variants.bats:100-125`
- Create: `tests/jsonc/assert-openai-gpt-5-6-map.js`

**Step 1: Write the failing test**

Replace the GPT-5.5 presence check with a JSONC-aware assertion script. It must require Sol, Terra, and Luna, reject every GPT-5.5 reference, and verify each role, fallback, and concurrency mapping.

**Step 2: Run test to verify it fails**

Run:

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace node:22-bookworm bash -lc '
  set -euo pipefail
  apt-get update -qq
  apt-get install -y --no-install-recommends -qq jq
  tmp_jsonc_dir="$(mktemp -d)"
  trap "rm -rf \"$tmp_jsonc_dir\"" EXIT
  cp tests/jsonc/package*.json "$tmp_jsonc_dir/"
  npm --prefix "$tmp_jsonc_dir" ci --silent
  NODE_PATH="$tmp_jsonc_dir/node_modules" tests/bats-core/bin/bats --timing tests/lint/test_config_variants.bats
'
```

Expected: FAIL because the active configuration still references `openai/gpt-5.5`.

### Task 2: Apply the bootstrap configuration map

**Files:**
- Modify: `bootstrap/config/variants/openai-chatgpt/oh-my-openagent.jsonc`
- Modify: `bootstrap/config/.opencode-docker-config-version`

**Step 1: Write minimal configuration changes**

Map `sisyphus`, `hephaestus`, `prometheus`, `metis`, `oracle`, `momus`, `atlas`, `ultrabrain`, `visual-engineering`, `unspecified-high`, and `artistry` to Sol with the role-appropriate `medium`, `high`, or `xhigh` effort. Map `deep` to Terra/xhigh and `writing` to Terra/medium. Map the `explore` and `librarian` fallbacks to Luna and the `multimodal-looker` fallback to Sol. Replace the single GPT-5.5 concurrency entry with Sol, Terra, and Luna entries and increment the managed config version from `25` to `26`.

**Step 2: Run the focused test to verify it passes**

Run the same focused Bats command in Docker.

Expected: PASS.

### Task 3: Verify the managed configuration and publish

**Files:**
- Modify: `docs/plans/2026-07-12-gpt-5-6-model-map.md`

**Step 1: Run focused lint and configuration checks**

Run: `docker compose run --rm test bats tests/lint/test_config_variants.bats` and validate the JSONC file with the repository helper.

Expected: all focused checks pass and no active `openai/gpt-5.5` reference remains.

**Step 2: Commit and publish**

Stage only the plan, bootstrap config, version marker, and focused test. Create a conventional commit, push `codex/gpt-5-6-model-map-v2`, and open a draft pull request with the model-selection rationale and verification output.
