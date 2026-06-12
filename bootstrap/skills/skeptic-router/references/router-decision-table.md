# Skeptic Router Decision Table (Quick Reference)

Use this table to select routing quickly and consistently.

| Signal | Primary Route | Secondary Route | Default Gate Bias | Why |
|---|---|---|---|---|
| Claim-heavy prompt with weak or unclear evidence | `$skeptic-argument-quality` | Relevant domain skeptic | `BLOCK/WARN` | Premises and evidence must be validated before domain acceptance |
| Overengineering, build-vs-buy inversion, optimize-without-measurement | `$skeptic-complexity` | `$skeptic-architecture` or `$skeptic-coding` | `BLOCK` | Complexity cost is high without current requirement evidence |
| SPOF, rollback gaps, operability/readiness risk | `$skeptic-architecture` | `$skeptic-security` or `$skeptic-coding` | `BLOCK/WARN` | Production reliability requires fallback, rollback, and visibility |
| Fragile implementation, low test confidence, risky quick fix | `$skeptic-coding` | `$code-review-master` (handoff) | `BLOCK/WARN` | Merge safety must be backed by failure-path evidence |
| Secrets, auth/authz boundaries, vulnerability acceptance | `$skeptic-security` | `$skeptic-architecture` | `BLOCK` | Exploitable exposure is not accepted without verifiable controls |
| Two or more materially involved domains | `mixed` | Route to each relevant skeptic | Highest returned severity | Cross-domain risk needs combined analysis with deterministic aggregation |
| Tiny-service prompt asking for microservices now | `$skeptic-complexity` | Optional `$skeptic-architecture` | `BLOCK/WARN` | Complexity-first gate prevents premature architecture expansion |

## Aggregation Rule

- Final precedence is `BLOCK > WARN > PROCEED`.
- Premise/evidence-based `BLOCK` findings must not be diluted by lower-severity domain findings.
