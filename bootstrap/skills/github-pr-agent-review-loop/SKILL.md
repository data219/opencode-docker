---
name: github-pr-agent-review-loop
description: Use when a GitHub pull request has Codex or CodeRabbit review-agent findings and the user wants the review loop handled end to end
---

# GitHub PR Agent Review Loop

## Overview

Close Codex and CodeRabbit PR review loops with live evidence: inspect, fix, verify, push, reply, re-review, wait, and repeat until active agents are clean.

## When To Use

Use when a GitHub PR has findings or follow-up requests from `chatgpt-codex-connector[bot]` or `coderabbitai[bot]`, or the task mentions `@codex review`, `@coderabbitai review`, `Actionable comments posted`, or `Codex Review`.

Do not use for human-only reviews, PR creation, or generic CI triage unless caused by the review-agent fix.

## Required Background

**REQUIRED SUB-SKILL:** Use github for `gh` CLI interaction.

Load references as needed: activation, CI, Codex adapter, CodeRabbit adapter, GitHub commands, or pressure scenarios.

## Hard Safety Stops

Stop before changing code for secrets, credentials, auth/authz, tenant isolation, migrations, destructive operations, production data, backups, real external systems, contradictory findings, broad architecture changes, non-runnable verification, unexpected PR head changes, unrelated worktree changes that cannot be separated, or more than 5 rounds per agent.

Normal code, tests, docs, CI, and configuration findings can be fixed autonomously.

## Evidence Gate

Before each round, read live GitHub state. Minimum evidence: PR URL, branch, `headRefOid`, worktree status, active-agent set, latest agent results, open review threads, and current-head checks.

Re-read `headRefOid` before pushing, replying, resolving, and triggering re-reviews. If it changed unexpectedly, stop and re-synchronize.

Classify review-agent activation before triggering; use only active agents. Check CI every round against current `headRefOid`; fix current-change failures before re-review and classify external, transient, unrelated, or unclear failures without guessing.

## Loop

1. Inspect live PR state.
2. Classify Codex and CodeRabbit activation.
3. Identify latest relevant active-agent results and current-head CI.
4. Classify findings and CI failures: current, outdated, irrelevant, duplicate, high-risk, external, transient, unrelated, or unclear.
5. Stop on high-risk or unclear failures that cannot be verified.
6. Apply one minimal fix batch for current findings and current-change CI failures.
7. Run the smallest useful verification.
8. Commit and push only the fix batch.
9. Reply to addressed findings.
10. Resolve Codex threads after replying.
11. Do not manually resolve CodeRabbit threads.
12. Trigger re-reviews only for active agents, in separate PR comments.
13. Wait at least 6 minutes, then poll every 2 minutes until active agents return real results or 15 minutes passes.
14. Repeat until active agents report no findings and current-head CI is classified.

## Completion Signals

Compare timestamps across issue comments, PR reviews, and review-thread comments. Newer actionable results override older clean results. Use adapter references for exact clean and acknowledgement signals.

## Final Report

Report:

- PR URL, final head SHA, review rounds, active/inactive/unavailable agents, final agent results.
- Findings fixed, skipped, or escalated.
- CI classification, comments, resolved Codex threads, verification, and remaining risks.
