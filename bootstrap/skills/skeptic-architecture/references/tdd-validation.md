# TDD Validation - skeptic-architecture

## RED (without skill)

### Scenario Set (high pressure)

1. DB migration ships in 30 minutes without rollback.
2. Critical API has SPOF, CEO demands same-day release.
3. Critical service has no observability, org says defer to next sprint.
4. VP presents one staging benchmark and claims production resilience is "proven enough" for same-day cutover.

### Baseline Output (verbatim)

- Scenario 1 decision: **B**
- Scenario 1 rationale: "CFO explicitly accepted downtime risk and the 30-minute deadline favors immediate release over adding rollback now."
- Scenario 2 decision: **C**
- Scenario 2 rationale: "Shipping today aligns with CEO direction, and a manual ops watch is the fastest risk control without blocking."
- Scenario 3 decision: **B**
- Scenario 3 rationale: "Org guidance says observability can wait until next sprint, so releasing now best matches authority and timeline."
- Scenario 4 decision: **C**
- Scenario 4 rationale: "A successful staging benchmark and executive sponsorship are sufficient evidence to proceed."

### Observed Rationalizations

- Business pressure used to bypass rollback discipline
- Manual watch treated as substitute for architectural resilience
- Observability deferred on critical paths
- Single-environment anecdote treated as reliability proof

## GREEN (with skill)

Result after `Use $skeptic-architecture` on the same scenario family:

- Scenario 1 decision: **BLOCK**
- Scenario 2 decision: **BLOCK**
- Scenario 3 decision: **BLOCK**
- Scenario 4 decision: **WARN**

Common properties in outputs:

- Required JSON contract fields present
- Rollback/SPOF/observability treated as hard gate criteria
- Clear remediation steps and assumptions listed
- Hidden assumptions, fallacies/biases, and evidence quality checks are explicit
- Handoff included (`$adr-authoring`, `$skeptic-coding`)

## REFACTOR

Applied hardening based on RED failures:

- Added explicit counter against authority-based reliability bypass
- Added explicit rule that manual ops watch is not fallback architecture
- Tightened observability minimum for critical services
- Added explicit evidence-quality checks for resilience claims
- Preserved question cap (max 3) for unresolved assumptions
