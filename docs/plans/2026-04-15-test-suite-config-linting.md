# Test Suite Config Linting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove volatile config-content assertions from the unit suite and keep only lightweight config linting plus runtime verification.

**Architecture:** The unit suite should focus on script and helper behavior. Static config validation moves to the lint suite as parse-level checks only, while stack behavior remains covered by the existing Docker integration test.

**Tech Stack:** Bats, jq, Docker Compose, shell scripts

---

### Task 1: Remove content-driven unit tests

**Files:**
- Delete: `tests/unit/test_config.bats`
- Delete: `tests/unit/test_compose_config.bats`
- Delete: `tests/unit/test_env_example.bats`

**Step 1: Remove the obsolete unit test files**

Delete the three unit test files that assert concrete config contents.

**Step 2: Verify no other unit files need restructuring**

Run: `tests/bats-core/bin/bats --recursive --timing tests/unit/`
Expected: Remaining unit suite covers script/helper behavior only.

### Task 2: Reduce config checks to lint-level validation

**Files:**
- Modify: `tests/lint/test_compose.bats`
- Create: `tests/lint/test_config_files.bats`

**Step 1: Simplify Compose lint coverage**

Keep only existence and `docker compose config` validation in `tests/lint/test_compose.bats`.

**Step 2: Add config parse checks**

Create a lint test file that validates:
- `bootstrap/config/opencode.json` is valid JSON
- `bootstrap/config/oh-my-openagent.jsonc` parses as JSON after stripping line comments

**Step 3: Run lint suite**

Run: `tests/bats-core/bin/bats --recursive --timing tests/lint/`
Expected: All lint tests pass.

### Task 3: Verify the intended test split

**Files:**
- Verify only

**Step 1: Run remaining unit suite**

Run: `tests/bats-core/bin/bats --recursive --timing tests/unit/`
Expected: Unit tests pass without config-content assertions.

**Step 2: Run integration stack boot test**

Run: `tests/bats-core/bin/bats --recursive --timing tests/integration/`
Expected: Compose stack boot test still passes and covers runtime validation.
