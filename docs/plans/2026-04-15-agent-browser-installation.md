# Agent Browser Image Installation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install `agent-browser` in the Docker image and switch the managed Oh My OpenAgent config back to the `agent-browser` browser automation provider.

**Architecture:** Keep the installation deterministic in `Dockerfile` with a pinned build arg and install-time browser setup. Treat the managed config files as the source of truth and verify the resulting container state with Docker-backed tests.

**Tech Stack:** Dockerfile, Docker Compose, Bats, npm, Oh My OpenAgent config

---

### Task 1: Add failing verification for managed config and container tooling

**Files:**
- Modify: `tests/integration/test_compose_stack_boot.bats`
- Test: `tests/lint/test_dockerfile.bats`

**Step 1: Write the failing test**

Add assertions that:
- `Dockerfile` declares a pinned `AGENT_BROWSER_VERSION` build arg.
- The booted container exposes the `agent-browser` binary.
- The booted container config contains `"provider": "agent-browser"`.

**Step 2: Run test to verify it fails**

Run:

```bash
bats tests/lint/test_dockerfile.bats tests/integration/test_compose_stack_boot.bats
```

Expected: failure because the image does not yet install `agent-browser` and the config still points to `playwright`.

**Step 3: Write minimal implementation**

Patch `Dockerfile` and managed config files only as needed to satisfy the new assertions.

**Step 4: Run test to verify it passes**

Run the same `bats` command and confirm all added assertions pass.

### Task 2: Install agent-browser in the image

**Files:**
- Modify: `Dockerfile`

**Step 1: Write the failing test**

Covered by Task 1.

**Step 2: Run test to verify it fails**

Covered by Task 1.

**Step 3: Write minimal implementation**

Add:
- a pinned `AGENT_BROWSER_VERSION` build arg with Renovate metadata
- global npm installation for `agent-browser@${AGENT_BROWSER_VERSION}`
- `agent-browser install` during image build

**Step 4: Run test to verify it passes**

Re-run lint and integration tests.

### Task 3: Restore managed provider selection

**Files:**
- Modify: `bootstrap/config/oh-my-openagent.jsonc`
- Modify: `data/config/oh-my-openagent.jsonc`

**Step 1: Write the failing test**

Covered by Task 1 container assertion.

**Step 2: Run test to verify it fails**

Covered by Task 1.

**Step 3: Write minimal implementation**

Change `browser_automation_engine.provider` back to `agent-browser` in both managed config copies.

**Step 4: Run test to verify it passes**

Re-run Docker-backed tests and confirm the started container receives the managed setting.
