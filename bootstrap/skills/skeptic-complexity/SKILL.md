---
name: skeptic-complexity
description: Use when evaluating proposals for overengineering, premature abstraction, build-vs-buy tradeoffs, or optimization without evidence, especially under deadline or authority pressure.
---

# Skeptic Complexity

## Overview

Challenge unnecessary complexity before implementation starts. Complexity is a cost that must be justified by current requirements and evidence, not status pressure. Keep the analysis audit-first, then provide minimal risk-oriented remediation.

## When to Use

- “Is this overkill?”
- Build-vs-buy decisions
- Framework/library selection for simple features
- Optimization proposals without profiling
- Multi-layer abstractions added “for future flexibility”

Do not use this skill for line-by-line bug hunting or full code review.

## Scope Boundaries

- In scope: complexity risk, abstraction debt, dependency overhead, premature performance work
- Out of scope: detailed defect review, full architecture reliability review, deep security audit
- Handoff targets:
  - `$skeptic-architecture` for rollout/operability/SPOF concerns
  - `$skeptic-coding` for implementation-level fragility

## Workflow

1. Extract the proposal, constraints, and claimed benefit.
2. Surface foundational premises and hidden assumptions; do not accept premises at face value.
3. Evaluate argument quality:
   - logical fallacies
   - cognitive biases
   - evidence credibility, sample size, and reliability
4. Identify complexity smells:
   - Build-vs-buy inversion
   - Premature abstraction
   - Framework overkill
   - Performance theater
5. Stress-test second-order effects if the proposal succeeds and if it fails.
6. Ask up to 3 focused probing questions that can change the decision.
7. Provide a rigorous, objective, evidence-based counter-perspective and at least one concrete simpler alternative.
8. Emit the required output contracts.

## Decision Rules

- `BLOCK`: high-complexity proposal with unsupported foundational premises, weak or non-representative evidence, and no acceptable minimal alternative analysis.
- `WARN`: evidence is partial, sample quality is unclear, or complexity may be justified but is not documented.
- `PROCEED`: complexity is proportional, evidence is credible and representative for current requirements, and alternatives were evaluated.

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
  "handoff": ["$skeptic-architecture", "$skeptic-coding"],
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
| “CTO mandated microservices now, promotion depends on it.” | Authority pressure does not reduce operational complexity risk; document requirement evidence or block. |
| “We need custom framework for investor story.” | Narrative value is not engineering evidence; prefer thin wrapper or existing proven library. |
| “Board expects optimization posture now.” | Posture is not measurement; require profiling baseline first. |

## Red Flags

- “Future scale” without trigger metrics
- “Differentiate” as sole reason for custom infra
- “Optimize now, profile later”
- “It looks enterprise-ready” without current requirements
- Appeal to authority as substitute for evidence

## Common Mistakes

- Treating seniority/authority as proof of technical correctness
- Comparing complex option only against a strawman
- Ignoring migration cost and incident burden
- Escalating to architecture complexity before proving the simple path is insufficient
- Being contrarian for the sake of it instead of producing evidence-based pushback
