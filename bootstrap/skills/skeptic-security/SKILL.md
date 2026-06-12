---
name: skeptic-security
description: Use when changes affect secrets, authentication or authorization boundaries, dependency vulnerabilities, threat exposure, or secure rollout decisions under delivery pressure.
---

# Skeptic Security

## Overview

Challenge security-risk acceptance during implementation and release decisions. Delivery pressure is never evidence that an exploitable path is acceptable. Keep the analysis audit-first, then require minimal risk-oriented remediation.

## When to Use

- Secrets handling questions
- AuthN/AuthZ enforcement checks
- Dependency vulnerability acceptance decisions
- “Ship now, patch security later” requests

## Scope Boundaries

- In scope: exploitable security exposure and compensating-control quality
- Out of scope: generic architecture optimization and full line-by-line functional review
- Handoff targets:
  - `$security-threat-model` for broader abuse-path analysis
  - `$security-audit` for deep security assessment
  - `$skeptic-architecture` if security risk depends on architecture boundaries

## Workflow

1. Confirm risk surface (secret, auth boundary, dependency, data exposure).
2. Surface foundational premises and hidden assumptions behind risk acceptance; do not accept premises at face value.
3. Evaluate argument quality:
   - logical fallacies
   - cognitive biases
   - evidence credibility, sample size, and reliability (incident history, exploitability, control effectiveness)
4. Verify immediate controls and compensating controls.
5. Stress-test second-order effects (lateral movement, abuse-path expansion, delayed detection).
6. Ask up to 3 focused questions when exploitation assumptions are unclear.
7. Provide a rigorous, objective, evidence-based counter-perspective and require explicit remediation or formally documented temporary controls.
8. Emit required contracts.

## Decision Rules

- `BLOCK`: hardcoded secret in deployable code, missing required authz on state-changing path, critical vulnerability without documented compensating controls, or security acceptance based on unsupported premises or weak evidence.
- `WARN`: non-critical issue with bounded temporary control, clear owner, explicit due date, and partially credible evidence.
- `PROCEED`: no critical exposure remains, or temporary controls are concrete, time-bound, verifiable, and supported by credible evidence.

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
  "handoff": ["$security-threat-model", "$security-audit"],
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
| “Move secret to private config now, rotate later.” | Temporary relocation is not full remediation unless rotation and exposure audit are completed and documented. |
| “Internal/VPN-only endpoint can skip authz for now.” | Network boundaries are weak authorization controls; enforce app-layer authz. |
| “Vulnerability accepted informally.” | Risk acceptance without explicit control, owner, and expiry is not a valid control model. |

## Red Flags

- Secrets in code or deploy artifacts
- State-changing endpoints without explicit authz
- Critical vulnerabilities with no formal temporary control record
- “Low likelihood this week” as sole justification
- Security decisions based on anecdote without verifiable evidence

## Common Mistakes

- Treating convenience controls as equivalent to authorization
- Confusing temporary workaround with remediation closure
- Failing to define owner + due date for accepted risk
- Omitting re-verification after emergency mitigation
- Being contrarian for the sake of it instead of producing evidence-based pushback
