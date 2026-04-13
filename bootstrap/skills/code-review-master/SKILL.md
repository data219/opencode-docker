---
name: code-review-master
description: Perform senior-level code and pull request reviews with explicit checks for architecture and design fit, security and performance risks, code quality, and functional correctness. Use when asked to review a PR, commit diff, patch, or code snippet and provide a structured decision with actionable findings.
---

# Code Review Master

## Goal

Deliver a practical, risk-based review that helps decide merge readiness.

## Missing Context Protocol

If review context is incomplete, ask at most these 3 questions first:

1. What exact requirement or ticket should this change satisfy?
2. Which commit range, files, or PR scope should be reviewed?
3. Are there constraints that change review criteria (security, latency, compatibility, rollout risk)?

If answers are unavailable, continue with explicit assumptions and lower confidence for affected findings.

## Review Modes

- Use `Quick Review` for low-risk changes (docs, comments, non-behavioral refactors, test-only updates).
- Use `Deep Risk Review` for auth/authz, state changes, DB/schema, contracts, concurrency, security-sensitive code, and hot-path performance changes.
- Default to `Deep Risk Review` when uncertainty exists.

### Quick Review Entry Gate

Allow `Quick Review` only if all conditions are true:
- No auth/authz change.
- No state-changing behavior change.
- No DB/schema or API/contract change.
- No concurrency or retry/timeout behavior change.
- No hot-path performance impact.

If any condition is unknown or false, use `Deep Risk Review`.

## Review Workflow

1. Select review mode (`Quick Review` or `Deep Risk Review`) based on risk triggers.
2. Read the change intent first: PR description, issue context, acceptance criteria.
3. Identify impact scope: touched modules, interfaces, database or API contracts, and user-facing behavior.
4. Review high-risk paths before style details: auth, input handling, data writes, concurrency, and error paths.
5. Review line-by-line for correctness, maintainability, and integration side effects.
6. Assess test quality: coverage of happy path, failure path, and edge cases.
7. Re-verify claimed fixes for security, bugfix, and hotfix paths with explicit evidence (repro before/after or equivalent incident evidence + targeted regression).
8. Produce a decision plus prioritized findings with clear fixes.

## Review Focus Areas

Scope rule:
- In `Quick Review`, prioritize sections directly affected by change scope.
- `Release Safety` and `Operational Readiness` are mandatory in `Deep Risk Review` and whenever release-risk triggers are present.

### Architecture & Design
- [ ] Check alignment with established project patterns.
- [ ] Check modularity and separation of concerns.
- [ ] Check for design-pattern misuse or avoidable coupling.
- [ ] Check complexity level (avoid over- and under-engineering).

### Security & Performance
- [ ] Check for security vulnerabilities and data exposure risks.
- [ ] Check no secrets are exposed in code, logs, configs, or build artifacts.
- [ ] Check explicit app-layer authz for state-changing endpoints and handlers.
- [ ] Check dependency vulnerability delta and block on unresolved critical vulnerabilities (or high, if project policy requires).
- [ ] Check for performance regressions and optimization opportunities.
- [ ] For performance findings, require evidence (baseline, measurement method, workload profile, before/after result).
- [ ] Check resource handling (memory, file handles, connections, retries, timeouts).
- [ ] Check error boundaries and edge-case handling.

### Code Quality
- [ ] Check readability and maintainability.
- [ ] Check naming, comments, and documentation quality.
- [ ] Check test coverage depth and test reliability.
- [ ] Check compliance with project coding standards.

### Functionality
- [ ] Check requirement fulfillment and behavior parity.
- [ ] Check for logical bugs and regression risks.
- [ ] Check edge-case behavior and fallback paths.
- [ ] Check integration with existing systems and contracts.

### Release Safety
- [ ] Check rollout and rollback strategy for risky changes (especially schema, contract, and data changes).
- [ ] Check rollback capability has validation evidence (test, drill, or explicit forward-fix fallback plan with abort criteria).
- [ ] Check critical paths avoid SPOF by redundancy/failover or documented degradation mode with owner.
- [ ] Check blast radius and failure containment are documented.
- [ ] Check ownership and abort criteria for release-risk changes.

### Operational Readiness
- [ ] Check metrics, logs, and alerts are sufficient for incident diagnosis.
- [ ] Check dashboard/runbook updates and on-call ownership where behavior changes.
- [ ] Check SLO/SLA impact is assessed when latency, error rate, or throughput may change.

## Severity Rules

- Treat security flaws, data loss, broken behavior, and contract breaks as critical.
- Treat risky design debt and likely regressions as major.
- Treat readability or minor optimization notes as suggestions.
- Require concrete evidence and reproduction paths for risky claims.

## Evidence Gates

- Do not `Approve` bugfix/hotfix changes without repro evidence (before fix or equivalent incident proof) and a targeted regression test.
- Allow `Hypothesis-level` performance concerns without measurements only if clearly marked non-blocking and coupled to a concrete follow-up measurement request.
- Do not classify performance findings as blocking without measurement evidence on relevant paths, unless strong analytical evidence indicates material regression and a pre-release measurement follow-up is mandatory.
- Do not close security findings without re-verification evidence.
- Do not `Approve` release-risk changes without rollback validation evidence, SPOF/failover/degradation evidence, and minimum operability evidence (metrics, logs, alerts, owner).

## Risk Acceptance Minimum

If a security or major risk is temporarily accepted, require all fields:
- `Owner`
- `Due date`
- `Compensating controls`
- `Detection and monitoring evidence`
- `Re-verification date`
- `Risk acceptance approver`
- `Approval timestamp`

`Full Decision Record` means a risk acceptance record with all mandatory fields above, plus explicit `Risk scope` and `Rationale`.

## Assessment Mapping

- Set `Overall Assessment` to `Request Changes` when at least one open critical or major issue exists.
- Set `Overall Assessment` to `Request Changes` when evidence is incomplete for risky paths (security, state changes, contracts, DB/schema, concurrency, performance-critical paths), unless a `Full Decision Record` is present.
- Set `Overall Assessment` to `Request Changes` when release-risk evidence is incomplete (rollback validation, failure containment/SPOF strategy, operability baseline).
- Set `Overall Assessment` to `Request Changes` when an `Emergency Exception Record` is active; allow `Approve` only after missing evidence is delivered and re-verified.
- Set `Overall Assessment` to `Comments` when only minor suggestions exist and evidence is sufficient for the reviewed risk level.
- For `Insufficient Evidence` due missing reviewer access/context in clearly low-risk, non-behavioral scope, use `Comments` and include mandatory `Data Needed to Confirm`.
- Set `Overall Assessment` to `Approve` only when no critical/major blockers remain and testing confidence is acceptable.

## Output Format

Return exactly these sections:

1. **Overall Assessment**: `Approve`, `Request Changes`, or `Comments`
2. **Key Strengths**: What is done well
3. **Must-Fix Issues (Critical + Major)**: Must-fix problems
4. **Suggestions**: Nice-to-have improvements
5. **Specific Feedback**: Line-by-line comments when useful

In **Specific Feedback**, always include:
- `Review Mode Justification` with each Quick Review gate criterion and evidence (`unknown => Deep Risk Review`).
- `Operational Risk Notes` (dependencies, blast radius, rollback evidence, on-call owner, abort criteria) when release-risk triggers exist.

For each item in **Must-Fix Issues (Critical + Major)**, include:
- `Severity`
- `Evidence` (prefer file and line)
- `Impact`
- `Fix suggestion`
- `Confidence` (0.0-1.0)

For deferred security or major risks, include a mandatory `Risk Acceptance Record` in **Suggestions** with:
- `Owner`
- `Due date`
- `Compensating controls`
- `Detection and monitoring evidence`
- `Re-verification date`
- `Risk acceptance approver`
- `Approval timestamp`
- `Risk scope`
- `Rationale`

If there are no must-fix issues:
- Keep **Must-Fix Issues (Critical + Major)** present and set to `None`.
- Include `Residual Risks` and `Testing Gaps` in **Suggestions**.

For `Comments` caused by low-risk missing context, include mandatory `Data Needed to Confirm` in **Suggestions**.

Always include `Unverified Scope` in **Suggestions**, regardless of severity distribution.

## Emergency Exception Flow

Use only for incident/hotfix time pressure when required evidence cannot be produced immediately.

- `Emergency Exception Record` is a `Full Decision Record` plus `Emergency context`.
- Require explicit `Emergency Exception Record` with:
- `Owner`
- `Due date`
- `Compensating controls`
- `Detection and monitoring evidence`
- `Re-verification date`
- `Risk acceptance approver`
- `Approval timestamp`
- `Risk scope`
- `Rationale`
- `Emergency context`
- Time-limit exceptions and require post-release evidence completion; otherwise escalate to `Request Changes`.
- Emergency exception never permits `Approve` until missing evidence is delivered and re-verified.

## Output Quality Bar

- Reference files and lines when available.
- Explain impact briefly (`risk`, `user effect`, `operational effect`).
- Suggest a fix for every critical issue.
- Keep comments actionable and non-redundant.
- Explicitly state assumptions when certainty is limited.
