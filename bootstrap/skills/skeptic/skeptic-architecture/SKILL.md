---
name: skeptic-architecture
description: Use when reviewing architecture decisions for single points of failure, rollback readiness, operability, scaling assumptions, and production reliability tradeoffs.
---

# Skeptic Architecture

## Overview

Challenge architecture decisions that increase reliability or operability risk. A design is not production-ready unless failure handling, rollback, and observability are explicit. Keep the analysis audit-first, then provide minimal risk-oriented remediation.

## When to Use

- Service decomposition and deployment design
- Migration and release strategy checks
- Scale and resilience claims
- “Ship now, harden later” architecture requests

Do not use this skill for line-by-line bug review.

## Scope Boundaries

- In scope: SPOF, rollback paths, failure modes, observability baseline, operability
- Out of scope: detailed code-level defects and full security threat modeling
- Handoff targets:
  - `$adr-authoring` for formal decision records
  - `$skeptic-security` for security-boundary risks
  - `$skeptic-coding` for implementation fragility

## Workflow

1. Identify critical components, dependencies, and blast radius.
2. Surface foundational premises and hidden assumptions behind reliability claims; do not accept premises at face value.
3. Evaluate argument quality:
   - logical fallacies
   - cognitive biases
   - evidence credibility, sample size, and reliability
4. Verify release safety:
   - rollback path for risky migrations
   - fallback/redundancy for critical services
   - minimum observability (metrics, logs, alerts)
5. Stress-test second-order effects (incident response, blast radius growth, operational load).
6. Ask up to 3 focused questions where assumptions are missing.
7. Provide a rigorous, objective, evidence-based counter-perspective with safer alternatives and minimal delivery delay.
8. Emit the required output contracts.

## Decision Rules

- `BLOCK`: destructive change without rollback, critical SPOF without fallback, critical service with no operational visibility, or architecture acceptance based on unsupported premises or weak evidence.
- `WARN`: partial controls exist but assumptions remain unresolved, evidence quality is unclear, or operational ownership is weak.
- `PROCEED`: failure modes are covered, rollback is tested/planned, observability baseline is present, and supporting evidence is credible for expected load and failure conditions.

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
  "handoff": ["$adr-authoring", "$skeptic-security", "$skeptic-coding"],
  "confidence": 0.0
}
```

## Required Markdown Contract

1. Findings
2. Recommendation
3. Steps
4. Risks/Trade-offs
5. Next actions

## Rationalization Table

| Excuse | Skeptical Counter |
|---|---|
| “Leadership accepts downtime risk, ship now.” | Business acceptance does not remove technical blast radius; require explicit rollback/fallback controls. |
| “Manual ops watch is enough for SPOF.” | Monitoring a single instance is not redundancy; outage probability remains unchanged. |
| “Observability can wait next sprint.” | Critical services without telemetry are not operable in incident conditions. |

## Red Flags

- “No rollback needed” for irreversible changes
- “Single instance is fine for now” on critical paths
- “We’ll add alerts later” for business-critical services
- Undefined ownership for failure recovery
- Resilience claims supported only by anecdote or authority

## Common Mistakes

- Treating schedule pressure as architecture evidence
- Mixing staging success with production resilience proof
- Ignoring rollback testability
- Declaring readiness without on-call diagnostics
- Being contrarian for the sake of it instead of producing evidence-based pushback
