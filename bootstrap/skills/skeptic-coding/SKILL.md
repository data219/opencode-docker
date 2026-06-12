---
name: skeptic-coding
description: Use when implementation changes may hide fragile assumptions, missing failure-path tests, unsafe quick fixes, or side effects that are not covered by current checks.
---

# Skeptic Coding

## Overview

Challenge implementation-level fragility before merge. This skill does not replace broad review checklists; it enforces skeptical lenses on assumptions, failure modes, and side effects with an audit-first posture.

## When to Use

- Hotfix pressure with unclear root cause
- Refactors with uncertain side effects
- Green CI but low confidence in behavior safety
- Happy-path-only tests on risky code

## Scope Boundaries

- In scope: fragile assumptions, missing failure tests, hidden side effects, risky shortcuts
- Out of scope: complete code-review rubric and style policy
- Mandatory handoff:
  - For non-trivial diffs, include `$code-review-master` in `handoff`
  - Optional: `$requesting-code-review` for branch/diff-driven review orchestration

## Workflow

1. Determine whether the change is trivial or non-trivial.
2. Surface foundational premises and hidden assumptions behind "safe to merge" claims; do not accept premises at face value.
3. Evaluate argument quality:
   - logical fallacies
   - cognitive biases
   - evidence credibility, sample size, and reliability (for test and repro claims)
4. Inspect failure modes and assumptions:
   - untested null/error paths
   - quick fixes without reproduction evidence
   - behavior changes hidden by refactor
5. Stress-test second-order effects (regressions under load, rollback complexity, observability blind spots).
6. Ask up to 3 focused questions where safety is unclear.
7. Provide a rigorous, objective, evidence-based counter-perspective and require targeted remediation steps before merge.
8. Emit required contracts with mandatory handoff rules.

## Decision Rules

- `BLOCK`: unsafe quick fix without repro evidence on non-trivial change, high-risk behavior path with no failure-path test coverage, or merge safety claimed from unsupported premises/weak evidence.
- `WARN`: confidence gap exists but mitigations are straightforward and planned before release, with partially credible evidence.
- `PROCEED`: risky paths are covered, assumptions are explicit, evidence is credible for safety claims, and non-trivial changes have review handoff.

## Required JSON Contract

```json
{
  "decision": "PROCEED | WARN | BLOCK",
  "summary": "string",
  "findings": [
    {
      "severity": "BLOCKER | MAJOR | MINOR",
      "title": "string",
      "evidence": "string",
      "impact": "string",
      "fix_suggestion": "string",
      "scope": "string"
    }
  ],
  "assumptions": ["string"],
  "required_next_steps": ["string"],
  "handoff": ["$code-review-master"],
  "confidence": 0.0
}
```

If diff is non-trivial, `handoff` MUST include `$code-review-master`.

## Required Markdown Contract

1. Findings
2. Recommendation
3. Steps
4. Risks/Trade-offs
5. Next actions

## Rationalization Table

| Excuse | Skeptical Counter |
|---|---|
| “Patch now, test later.” | Sequence inversion hides defects; require repro evidence and failure-path validation first. |
| “CI is green, so we are safe.” | Green CI proves configured checks only; hidden side effects still require targeted validation. |
| “Add TODO tests after launch.” | Deferred tests are unbounded risk debt on behavior-critical paths. |

## Red Flags

- No reproduction evidence for urgent bugfixes
- Merge rationale based only on schedule pressure
- Refactor-risk dismissed because lint/tests pass
- Missing tests for error/null/timeout branches
- "Green CI" treated as complete safety proof without targeted checks

## Common Mistakes

- Conflating “fastest merge” with “lowest risk”
- Treating unknown behavior as acceptable debt
- Duplicating full review checklists instead of handing off to `$code-review-master`
- Failing to state what was not verified
- Being contrarian for the sake of it instead of producing evidence-based pushback
