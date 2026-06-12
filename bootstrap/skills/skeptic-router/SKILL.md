---
name: skeptic-router
description: Use when a request may require one or more specialized skeptic skills and you need deterministic routing, aggregation, and a final gate decision.
---

# Skeptic Router

## Overview

Route skeptical analysis to the correct specialized skill, then aggregate outcomes into one deterministic decision.

## When to Use

- Claim-heavy or hypothesis-driven prompts with unclear evidence quality
- Mixed prompts spanning complexity, architecture, coding, and security
- Ambiguous requests where wrong specialist choice can miss risk
- Need for a single gate decision from multiple skeptic perspectives

Do not use this skill for deep analysis itself.

## Routing Rules

- Route to `$skeptic-argument-quality` when prompts are claim- or hypothesis-driven and rely on weak evidence, unclear sample quality, or unstated premises.
- Route to `$skeptic-complexity` when proposal risks overengineering or premature optimization.
- Route to `$skeptic-architecture` when SPOF, rollback, operability, or reliability readiness is in question.
- Route to `$skeptic-coding` when implementation fragility or test confidence is the issue.
- Route to `$skeptic-security` when secrets, auth boundaries, or vulnerability exposure appears.
- Route to `mixed` when at least two domains are materially involved.

For tiny-service microservice questions, default to `$skeptic-complexity` first, then optionally add `$skeptic-architecture`.
For claim-heavy prompts touching a delivery domain, run `$skeptic-argument-quality` first, then add the domain skeptic.

## Aggregation Rules

1. Collect specialized outputs using the common JSON contract.
2. Precedence for final decision: `BLOCK` > `WARN` > `PROCEED`.
3. Merge findings without dropping higher severity items.
4. Deduplicate equivalent findings by evidence and fix direction.
5. Keep open questions to maximum 3 total across all routed skills.
6. Do not dilute premise/evidence-based `BLOCK` findings with lower-severity domain outputs.

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
  "handoff": [
    "$skeptic-argument-quality",
    "$skeptic-complexity",
    "$skeptic-architecture",
    "$skeptic-coding",
    "$skeptic-security"
  ],
  "confidence": 0.0
}
```

## Required Markdown Contract

1. Findings
2. Recommendation
3. Steps
4. Risks/Trade-offs
5. Next actions

## Common Mistakes

- Sending all requests to one monolithic skeptic
- Skipping argument-quality checks on claim-heavy prompts
- Ignoring cross-domain issues that require `mixed` routing
- Downgrading final severity when any domain returned `BLOCK`
- Emitting more than three unresolved questions

## References

- `references/evaluation-matrix.md`
- `references/research-summary.md`
- `references/tdd-validation.md`
- `references/regression-prompts.md`
- `references/router-decision-table.md`
