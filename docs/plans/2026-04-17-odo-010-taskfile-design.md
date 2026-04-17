# ODO-010 Taskfile Replacement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the repository `Makefile` with a small `Taskfile.yml` that covers daily Docker workflows and preserves the existing Bats-based test commands.

**Architecture:** Introduce `Taskfile.yml` as the single local command entrypoint. Keep task scope intentionally small: Docker Compose daily workflows plus direct Bats test execution, then update the repository documentation and TODO state to match the new interface.

**Tech Stack:** Task, Docker Compose, Bats, Markdown documentation

---

### Task 1: Add the new task entrypoints

**Files:**
- Create: `Taskfile.yml`

**Step 1: Define the daily workflow tasks**

Add tasks for `config`, `build`, `up`, `logs`, `shell`, and `opencode`.

**Step 2: Define the test tasks**

Add `test-unit`, `test-integration`, `test-lint`, `test-all`, and `test` using the existing Bats command shapes from `Makefile`.

**Step 3: Keep commands explicit**

Use direct commands instead of wrapping `make`, and preserve the single-threaded integration test behavior.

### Task 2: Remove the old command entrypoint

**Files:**
- Delete: `Makefile`

**Step 1: Remove the now-obsolete `Makefile`**

Delete the file once every target has an equivalent Task entrypoint.

### Task 3: Update repository documentation

**Files:**
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
- Modify: `TODO.md`

**Step 1: Update prerequisite and usage text**

Replace `make`-based instructions with `task` where the repo now expects Task as the primary command interface.

**Step 2: Document the daily task entrypoints**

Keep the new section short and aligned with the actual tasks implemented in `Taskfile.yml`.

**Step 3: Mark the TODO as complete**

Flip `ODO-010` to done in the status overview after the implementation is finished.

### Task 4: Verify the replacement locally

**Files:**
- Verify: `Taskfile.yml`

**Step 1: Render the available tasks**

Run: `task --list`
Expected: the new daily and test tasks are listed.

**Step 2: Validate Compose rendering through Task**

Run: `task config`
Expected: `docker compose config` succeeds.

**Step 3: Smoke-test one preserved test task**

Run: `task test-lint`
Expected: the Bats lint suite runs successfully.
