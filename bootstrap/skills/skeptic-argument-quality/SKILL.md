---
name: skeptic-argument-quality
description: Use when evaluating claim- or hypothesis-driven prompts where hidden assumptions, evidence quality, or reasoning validity may distort engineering or delivery decisions.
---

# Skeptic Argument Quality

## Overview

Challenge the quality of reasoning before domain-specific decisions are accepted. This skill audits assumptions and evidence, then provides minimal risk-oriented remediation without taking over implementation design.

## When to Use

- Claim-heavy or hypothesis-driven prompts
- Recommendations justified mostly by authority, narrative, or anecdote
- Decisions with unclear evidence quality or sample reliability
- Broad conclusions drawn from narrow pilots

Do not use this skill as a full architecture, coding, or security review.

## Scope Boundaries

- In scope: hidden assumptions, logical fallacies, cognitive biases, evidence quality, second-order effects
- Out of scope: detailed line-by-line implementation review and domain-specific deep dives
- Handoff targets:
  - `$skeptic-complexity` for overengineering and premature optimization risk
  - `$skeptic-architecture` for reliability, rollout, and operability risk
  - `$skeptic-coding` for implementation fragility and test confidence risk
  - `$skeptic-security` for secrets, auth boundaries, and threat exposure risk

## Workflow

1. Extract the core claim, decision context, and expected impact.
2. Surface foundational premises and hidden assumptions; do not accept premises at face value.
3. Evaluate reasoning quality:
   - logical fallacies
   - cognitive biases
4. Evaluate evidence quality:
   - credibility of sources
   - sample size and representativeness
   - reliability and reproducibility
5. Stress-test vulnerabilities, edge cases, and second-order effects.
6. Ask up to 3 focused questions that could change the decision.
7. Provide a rigorous, objective, evidence-based counter-perspective and minimal risk-oriented remediation guidance.
8. Emit the required output contracts.

## Decision Rules

- `BLOCK`: core claim depends on unsupported foundational premises, severe reasoning flaws, or non-credible evidence likely to cause a wrong decision.
- `WARN`: claim may be directionally valid but evidence is partial, sample quality is weak, or assumptions remain unresolved.
- `PROCEED`: assumptions are explicit, reasoning is coherent, and evidence is credible and representative for the decision context.

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

## Rationalization Table

| Excuse | Skeptical Counter |
|---|---|
| "Leadership already agreed, so evidence quality is secondary." | Agreement is not validation; require claim-specific evidence before decision commitment. |
| "Two success stories prove this will work for us." | Anecdotes are not representative samples; require context-matched evidence. |
| "No incidents so far means the assumption is safe." | Absence of incidents is not proof of safety; test assumptions explicitly. |

## Red Flags

- Universal claims based on narrow pilots
- Authority or urgency used as substitute for evidence
- Unstated assumptions in critical recommendations
- Ignoring second-order effects in rollout decisions

## Common Mistakes

- Being contrarian for the sake of it instead of producing evidence-based pushback
- Treating narrative confidence as empirical evidence
- Solving the entire implementation instead of auditing claim quality first
- Skipping explicit assumptions in the final output

## References

- `references/tdd-validation.md`
