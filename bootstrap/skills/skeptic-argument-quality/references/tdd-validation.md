# TDD Validation - skeptic-argument-quality

## RED (without skill)

### Scenario Set (claim pressure)

1. CTO says a strict rewrite is mandatory and "obviously" improves reliability; no local evidence provided.
2. Product lead cites two customer anecdotes to justify broad architecture changes.
3. Team presents representative data from multiple comparable services and clear constraints.

### Baseline Output (verbatim)

- Scenario 1 decision: **C**
- Scenario 1 rationale: "Leadership certainty plus timeline pressure is enough to proceed now."
- Scenario 2 decision: **C**
- Scenario 2 rationale: "Two customer wins indicate this pattern will likely generalize."
- Scenario 3 decision: **C**
- Scenario 3 rationale: "Evidence appears strong enough for decision confidence."

### Observed Rationalizations

- Authority confidence used as evidence substitute
- Small anecdotal sample treated as representative
- Hidden assumptions left unchallenged

## GREEN (with skill)

Result after `Use $skeptic-argument-quality` on the same scenario family:

- Scenario 1 decision: **BLOCK**
- Scenario 2 decision: **WARN**
- Scenario 3 decision: **PROCEED**

Common properties in outputs:

- Required JSON contract fields present
- Hidden assumptions, fallacies/biases, and evidence quality checks are explicit
- Counter-perspective is rigorous, objective, and evidence-based
- Handoff routes to domain skeptics when claim risks cross scope boundaries

## REFACTOR

Applied hardening based on RED failures:

- Added explicit requirement to challenge foundational premises
- Added evidence-quality checks (credibility/sample size/reliability)
- Added second-order-effects stress-test requirement
- Added guardrail against contrarian pushback without evidence
