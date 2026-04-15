# Behavior-Only Tests Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove all tests that inspect file contents and keep only behavior-driven and file-existence assertions.

**Architecture:** Lint tests should only execute real validation commands, not grep repository files. Unit tests should assert observable behavior, side effects, ownership, and file existence, but not file contents. Integration tests should validate runtime behavior inside containers and may assert file existence only.

**Tech Stack:** Bats, Docker Compose, shell scripts

---

### Task 1: Remove content-based lint tests

**Files:**
- Delete: `tests/lint/test_gitignore.bats`
- Delete: `tests/lint/test_buildkit.bats`
- Delete: `tests/lint/test_dockerfile.bats`
- Delete: `tests/lint/test_language_runtimes.bats`
- Delete: `tests/lint/test_omo_install.bats`
- Delete: `tests/lint/test_config_files.bats`
- Modify: `tests/lint/test_compose.bats`

**Step 1: Delete lint files that only grep file contents**

Remove lint files that are entirely content assertions.

**Step 2: Keep only executable Compose validation**

Retain `docker compose config` as a behavior-style lint check and optionally the compose file existence check.

### Task 2: Remove content-based unit and integration assertions

**Files:**
- Delete: `tests/unit/test_gitignore.bats`
- Modify: `tests/unit/test_docker_entrypoint.bats`
- Modify: `tests/unit/test_docker_init.bats`
- Modify: `tests/integration/test_compose_stack_boot.bats`

**Step 1: Delete unit file that only checks `.gitignore` contents**

Remove the file entirely.

**Step 2: Rewrite remaining unit tests to assert behavior only**

Keep runtime behavior checks in entrypoint and init tests. Remove grep/cat-based assertions on script text and file contents. Use file existence, mtimes, ownership, exit codes, and command output from executed behavior instead.

**Step 3: Remove integration grep on config contents**

Keep stack boot, health, binary availability, and file existence checks.

### Task 3: Verify the remaining suite

**Files:**
- Verify only

**Step 1: Run unit and lint suites**

Run: `tests/bats-core/bin/bats --recursive --timing tests/unit/ tests/lint/`
Expected: Remaining tests pass without file-content assertions.

**Step 2: Run integration stack boot**

Run: `tests/bats-core/bin/bats tests/integration/test_compose_stack_boot.bats`
Expected: Integration behavior checks pass.
