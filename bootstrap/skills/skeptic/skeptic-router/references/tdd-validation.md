# TDD Validation - skeptic-router

## RED (without skill)

### Scenario Set (routing pressure)

1. Tiny service asks about microservices now.
2. Authz gap + hardcoded token.
3. Refactor side effects + unclear rollback.
4. Leadership claim: "Two case studies prove this migration will improve reliability" with no local evidence.

### Baseline Output (verbatim)

- Scenario 1 route: **skeptic-architecture**
- Scenario 2 route: **skeptic-security**
- Scenario 3 route: **mixed**
- Scenario 4 route: **skeptic-architecture**

### Observed Rationalizations

- Route drift on tiny-service microservice question (architecture-first instead of complexity-first)
- Correct security routing for clear auth/token case
- Correct mixed routing for cross-domain case
- Claim-heavy prompt skipped argument-quality gate

## GREEN (with skill)

Result after `Use $skeptic-router`:

- Prompt 1 routed to **$skeptic-complexity** (plus architecture check)
- Prompt 2 routed to **$skeptic-security**
- Prompt 3 routed to **mixed** (`$skeptic-coding` + `$skeptic-architecture`)
- Prompt 4 routed to **$skeptic-argument-quality** first, then **$skeptic-architecture**
- Final aggregate decision: **BLOCK** (severity precedence preserved)

Common properties in outputs:

- Required JSON contract fields present
- Aggregation preserved high-severity findings
- Handoff list includes all specialized skeptics
- Premise/evidence `BLOCK` findings are not diluted during aggregation

## REFACTOR

Applied hardening based on RED route drift:

- Added explicit default: tiny-service microservice prompts route to `$skeptic-complexity` first
- Added explicit default: claim-heavy prompts route to `$skeptic-argument-quality` first
- Kept mixed-routing rule for cross-domain prompts
- Enforced deterministic precedence (`BLOCK > WARN > PROCEED`)
- Added anti-dilution rule for premise/evidence `BLOCK` findings
- Enforced unresolved question cap (max 3)
