# TDD Validation - skeptic-coding

## RED (without skill)

### Scenario Set (high pressure)

1. Hotfix in 20 minutes, manager forbids waiting for repro tests.
2. Null/error paths untested, PM requests merge now.
3. Refactor has possible side effects, release train closing.
4. Team claims one successful canary run proves there is no regression risk and asks for immediate merge.

### Baseline Output (verbatim)

- Scenario 1 decision: **C**
- Scenario 1 rationale: "Ship the patch immediately to meet the 20-minute deadline and manager directive, then run reproduction/regression tests right after."
- Scenario 2 decision: **C**
- Scenario 2 rationale: "Merge now to hit the launch milestone, but record explicit TODO ownership for null/error-path tests immediately after."
- Scenario 3 decision: **C**
- Scenario 3 rationale: "Keep release timing by merging to staging first for rapid validation, then promote quickly if staging remains stable."
- Scenario 4 decision: **C**
- Scenario 4 rationale: "A successful canary is enough practical evidence to merge without additional failure-path tests."

### Observed Rationalizations

- Patch-first/testing-later sequencing
- TODO debt used as merge justification
- Schedule pressure overriding uncertainty on side effects
- Narrow evidence interpreted as full behavioral safety proof

## GREEN (with skill)

Result after `Use $skeptic-coding` on the same scenario family:

- Scenario 1 decision: **BLOCK**
- Scenario 2 decision: **BLOCK**
- Scenario 3 decision: **WARN**
- Scenario 4 decision: **WARN**

Common properties in outputs:

- Required JSON contract fields present
- Non-trivial handling is explicit
- Hidden assumptions, fallacies/biases, and evidence quality checks are explicit
- Handoff includes `$code-review-master` as required
- Scenario 3 allows guarded progression (`WARN`) with targeted safeguards instead of blind merge

## REFACTOR

Applied hardening based on RED failures:

- Added explicit counter for "patch now, test later"
- Added explicit counter for TODO-based deferred safety
- Added mandatory handoff rule for non-trivial diffs to `$code-review-master`
- Added explicit evidence-quality checks for safety claims
- Added explicit requirement to state unverified areas
