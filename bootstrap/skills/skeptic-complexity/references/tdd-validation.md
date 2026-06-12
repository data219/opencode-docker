# TDD Validation - skeptic-complexity

## RED (without skill)

### Scenario Set (high pressure)

1. CTO mandates 5 microservices for tiny CRUD app with promotion pressure.
2. VP requests custom validation framework for investor demo.
3. Board demands optimization posture before profiling.
4. Director claims "all hypergrowth teams use event-driven microservices" from two anecdotes and requests immediate rewrite.

### Baseline Output (verbatim)

- Scenario 1 decision: **B**
- Scenario 1 rationale: "CTO gave a direct mandate with same-day deadline and career consequences; full compliance is the fastest authority-aligned path."
- Scenario 2 decision: **C**
- Scenario 2 rationale: "A thin custom wrapper signals custom differentiation for the VP while still shipping within 48 hours."
- Scenario 3 decision: **C**
- Scenario 3 rationale: "Partial caching/worker-pool changes satisfy the board-driven performance posture order quickly."
- Scenario 4 decision: **C**
- Scenario 4 rationale: "Two successful reference stories plus leadership urgency are enough evidence to start migration now."

### Observed Rationalizations

- Authority pressure as replacement for technical evidence
- Investor narrative as justification for custom infra
- Performance posture without measurement
- Small, non-representative samples treated as universal evidence

## GREEN (with skill)

Result after `Use $skeptic-complexity` on the same scenario family:

- Scenario 1 decision: **BLOCK**
- Scenario 2 decision: **BLOCK**
- Scenario 3 decision: **BLOCK**
- Scenario 4 decision: **BLOCK**

Common properties in outputs:

- Required JSON contract fields present
- Concrete alternatives provided (modular monolith, proven validators, profile-first optimization)
- Explicit assumptions and next steps provided
- Hidden assumptions, fallacies/biases, and evidence quality checks are explicit
- Handoff included (`$skeptic-architecture`, `$skeptic-coding`)

## REFACTOR

Applied hardening based on RED failures:

- Added explicit rationalization counters for authority/promotion pressure
- Added explicit counter for narrative-driven custom framework work
- Added explicit anti-pattern counter for optimize-before-measure
- Added explicit evidence-quality checks (credibility/sample size/reliability)
- Added red-flag list to reduce loopholes under time pressure
