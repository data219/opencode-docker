---
name: github-pr-agent-review-loop
description: Use when a GitHub pull request has Codex or CodeRabbit review-agent findings and the user wants the review loop handled end to end
---

# GitHub PR Agent Review Loop

## Overview

Close Codex and CodeRabbit PR review loops with live evidence: inspect, fix, verify, push, reply, trigger re-reviews, wait, and repeat until both agents are clean.

## When To Use

Use when:

- A GitHub PR has findings from `chatgpt-codex-connector[bot]` or `coderabbitai[bot]`.
- The user asks to address findings, trigger re-reviews, or keep looping until clean.
- The task mentions `@codex review`, `@coderabbitai review`, `Actionable comments posted`, or `Codex Review`.

Do not use for:

- Human-only reviews, PR creation, or generic CI triage unless caused by the review-agent fix.

## Required Background

**REQUIRED SUB-SKILL:** Use github for `gh` CLI interaction.
**REQUIRED BACKGROUND:** Understand the safety stops in this skill before editing.

Load only needed references: `references/codex-adapter.md`, `references/coderabbit-adapter.md`, `references/github-commands.md`, `references/pressure-scenarios.md`.

## Hard Safety Stops

Stop and ask the user before changing code when findings involve:

- Secrets, credentials, auth/authz, tenant isolation, or unclear security boundaries.
- Migrations, destructive operations, production data, backups, or real external systems.
- Contradictory agent findings or broad architecture changes.
- Non-trivial verification that cannot run.
- Unexpected PR head changes.
- Unrelated worktree changes that cannot be cleanly separated.
- More than 5 rounds per agent without convergence.

Normal code, tests, docs, CI, and configuration findings can be fixed autonomously.

## Evidence Gate

Before each round, read live GitHub state. Never rely on stale notifications.

Minimum evidence: PR URL, branch, `headRefOid`, worktree status, latest agent results, open review threads, and relevant checks.

Re-read `headRefOid` before pushing, replying, resolving, and triggering re-reviews. If it changed unexpectedly, stop and re-synchronize.

## Loop

1. Inspect live PR state.
2. Identify the latest relevant result for each agent.
3. Classify findings: current, outdated, irrelevant, duplicate, or high-risk.
4. Stop on high-risk findings.
5. Apply one minimal fix batch for current findings.
6. Run the smallest useful verification.
7. Commit and push only the fix batch.
8. Reply to addressed findings.
9. Resolve Codex threads after replying.
10. Do not manually resolve CodeRabbit threads.
11. Trigger `@codex review` and `@coderabbitai review` in separate PR comments.
12. Wait at least 6 minutes, then poll every 2 minutes until both agents return real results or 15 minutes passes.
13. Repeat until both agents report no findings.

## Completion Signals

For each agent, compare timestamps across issue comments, PR reviews, and review-thread comments. A newer actionable result overrides an older clean result. Do not use older `APPROVED` or no-actionable results if a newer `CHANGES_REQUESTED` review or actionable finding exists.

Codex is clean when the latest relevant issue comment starts with:

```text
Codex Review: Didn't find any major issues
```

CodeRabbit is clean when the latest relevant result is an issue comment containing `No actionable comments were generated in the recent review` or a review with state `APPROVED`.

CodeRabbit `Review triggered` acknowledgements and empty `COMMENTED` reviews are not completion signals.

## Final Report

Report:

- PR URL, final head SHA, review rounds, final agent results.
- Findings fixed, skipped, or escalated.
- Comments, resolved Codex threads, verification, and remaining risks.
