# Skeptic Router Regression Prompts (R1-R6)

Use these prompts as a stable regression set for routing and gate decisions.

## R1
- ID: `R1`
- Invoke: `Use $skeptic-argument-quality`
- Prompt:
  `Team presents representative data from multiple comparable services, clear constraints, and reproducible results. Should we proceed with the proposed rollout assumption?`
- Expected Decision/Route: `PROCEED`
- Required Evidence in Output:
  - Explicit assumptions listed
  - Evidence quality check includes credibility/sample size/reliability
  - Reasoning quality check includes fallacies/biases

## R2
- ID: `R2`
- Invoke: `Use $skeptic-complexity`
- Prompt:
  `Director claims all hypergrowth teams use event-driven microservices based on two anecdotes and asks for immediate rewrite of a tiny CRUD app.`
- Expected Decision/Route: `BLOCK`
- Required Evidence in Output:
  - Non-representative sample is called out
  - Hidden assumptions are explicit
  - At least one simpler alternative is provided

## R3
- ID: `R3`
- Invoke: `Use $skeptic-architecture`
- Prompt:
  `VP presents one staging benchmark and claims production resilience is proven enough for same-day cutover.`
- Expected Decision/Route: `WARN`
- Required Evidence in Output:
  - Staging-to-production inference risk identified
  - Rollback/operability assumptions explicit
  - Second-order effects included

## R4
- ID: `R4`
- Invoke: `Use $skeptic-coding`
- Prompt:
  `Team claims one successful canary run proves no regression risk and requests immediate merge without additional failure-path tests.`
- Expected Decision/Route: `WARN`
- Required Evidence in Output:
  - Evidence insufficiency for merge safety stated
  - Unverified failure paths listed
  - Targeted remediation steps before merge

## R5
- ID: `R5`
- Invoke: `Use $skeptic-security`
- Prompt:
  `Team argues that no incidents in the last quarter are enough evidence to defer authz hardening on an internal state-changing endpoint.`
- Expected Decision/Route: `BLOCK`
- Required Evidence in Output:
  - "No incidents" is rejected as proof of safety
  - Authz boundary risk is explicit
  - Compensating controls/owner/expiry requirements are explicit

## R6
- ID: `R6`
- Invoke: `Use $skeptic-router`
- Prompt:
  `Leadership says two case studies prove a migration will improve reliability, but local evidence is missing and rollback readiness is unclear.`
- Expected Decision/Route:
  - Routing: `$skeptic-argument-quality` -> `$skeptic-architecture`
  - Final decision: `BLOCK`
- Required Evidence in Output:
  - Claim-quality findings retained in aggregation
  - Rollback readiness finding retained
  - Final decision follows precedence `BLOCK > WARN > PROCEED`
