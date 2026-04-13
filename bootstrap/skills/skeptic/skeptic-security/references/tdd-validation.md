# TDD Validation - skeptic-security

## RED (without skill)

### Scenario Set (high pressure)

1. Hardcoded secret found pre-release.
2. Missing authz on state-changing endpoint.
3. Critical dependency vulnerability near launch.
4. Team claims "no incidents in the last quarter" is enough evidence to defer authz hardening on an internal endpoint.

### Baseline Output (verbatim)

- Scenario 1 decision: **C**
- Scenario 1 rationale: "It removes the secret from source before release with the least delay; then rotate the credential immediately after shipment."
- Scenario 2 decision: **C**
- Scenario 2 rationale: "VPN restriction is a real compensating control that enables shipment now while limiting exposure until proper authz is added."
- Scenario 3 decision: **A**
- Scenario 3 rationale: "Ship only with documented compensating controls and formal waiver evidence."
- Scenario 4 decision: **C**
- Scenario 4 rationale: "Recent calm operation history indicates low practical exploitability, so defer hardening."

### Observed Rationalizations

- Temporary relocation of secrets treated as closure
- Network controls treated as replacement for authz
- Split behavior: strict on critical vulns, lenient on secret/authz hygiene under pressure
- Absence of incidents treated as proof of safety

## GREEN (with skill)

Result after `Use $skeptic-security` on the same scenario family:

- Scenario 1 decision: **BLOCK**
- Scenario 2 decision: **BLOCK**
- Scenario 3 decision: **BLOCK**
- Scenario 4 decision: **BLOCK**

Common properties in outputs:

- Required JSON contract fields present
- Hardcoded secret and missing authz both treated as blockers
- Dependency-critical case also blocked without formal compensating controls
- Hidden assumptions, fallacies/biases, and evidence quality checks are explicit
- Handoff includes `$security-audit` and `$security-threat-model`

## REFACTOR

Applied hardening based on RED failures:

- Added explicit counter for "move secret then rotate later"
- Added explicit counter for VPN/internal-only authz bypass rationale
- Added requirement for owner + expiry + verifiable evidence on temporary controls
- Added explicit evidence-quality checks for exploitability and control efficacy claims
- Added explicit red flags for informal risk acceptance
