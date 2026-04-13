# Skeptiker Skill & Input Evaluation Matrix

## Model

Scale per criterion: `0-5`.

Weighted score:

`score = codex_fit*0.25 + skeptic_sharpness*0.20 + non_duplication_vs_code_review_excellence*0.15 + actionability*0.15 + gate_readiness*0.15 + maintainability_stack_fit*0.10`

## Candidates (fixed pool)

| Candidate | Type | Codex Fit 25% | Skeptic Sharpness 20% | Non-Duplication 15% | Actionability 15% | Gate Readiness 15% | Maintainability/Stack Fit 10% | Weighted Score | Notes |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| OpenAI `security-threat-model` | curated skill | 5.0 | 4.5 | 4.8 | 4.2 | 4.0 | 4.0 | 4.47 | Strong security lens, good handoff target |
| OpenAI `gh-fix-ci` | curated skill | 5.0 | 3.5 | 4.2 | 4.8 | 4.8 | 4.0 | 4.33 | High evidence/gate value for CI failures |
| Outfitter `simplify` (input pattern) | 3rd-party input | 2.5 | 4.8 | 4.5 | 4.6 | 3.8 | 3.5 | 3.94 | Excellent complexity lens; requires Codex adaptation |
| Local `security-audit` | local skill | 4.5 | 4.2 | 4.0 | 4.0 | 3.8 | 4.8 | 4.21 | PHP/OWASP aligned, optional deep audit handoff |
| Local `code-review-master` | local skill | 5.0 | 4.0 | 5.0 | 4.8 | 3.5 | 4.8 | 4.56 | Use as mandatory coding handoff |
| Local `architecture-patterns` | local skill | 5.0 | 3.7 | 4.5 | 3.9 | 3.2 | 4.5 | 4.14 | Architecture background, not a gate skill |
| Local `debugging-strategies` | local skill | 5.0 | 3.8 | 4.4 | 4.1 | 3.4 | 4.6 | 4.20 | Useful for repro/root-cause skepticism |
| Local `enterprise-readiness` | local skill | 5.0 | 3.9 | 4.3 | 4.4 | 4.3 | 4.7 | 4.43 | Quality-gate patterns + automation references |
| Local `skeptic-argument-quality` | local skill | 4.8 | 4.7 | 4.5 | 4.5 | 4.6 | 4.4 | 4.61 | Strong claim-quality gate; routes ambiguous prompts before domain specialization |
| Local `skeptic-original` | local skill | 3.2 | 4.6 | 4.2 | 3.8 | 2.8 | 3.6 | 3.70 | Legacy baseline (optional); opt-in comparison input, not router default |
| OpenAI `security-best-practices` | curated skill | 5.0 | 3.6 | 4.6 | 3.9 | 3.3 | 3.5 | 4.06 | Good reference, less deterministic than threat-model |
| OpenAI `security-ownership-map` | curated skill | 5.0 | 3.4 | 4.7 | 4.0 | 3.9 | 3.2 | 4.04 | Ownership risk lens, not direct code gate |
| Outfitter `code-review` (input pattern) | 3rd-party input | 2.5 | 4.4 | 2.2 | 4.7 | 3.9 | 3.0 | 3.33 | Useful structure, but overlaps heavily with code-review-master |
| Outfitter `architecture` (input pattern) | 3rd-party input | 2.5 | 4.2 | 4.0 | 4.3 | 3.7 | 3.3 | 3.68 | Good architecture prompts; needs adaptation |
| Outfitter `debugging` (input pattern) | 3rd-party input | 2.5 | 4.0 | 4.1 | 4.2 | 3.6 | 3.2 | 3.51 | Evidence-first mindset; Codex-port needed |
| Outfitter `performance` (input pattern) | 3rd-party input | 2.5 | 3.9 | 4.4 | 4.0 | 3.7 | 3.2 | 3.53 | No-optimization-without-measurement useful |
| Outfitter `skeptic` agent spec | 3rd-party input | 1.5 | 4.8 | 4.3 | 4.6 | 4.2 | 3.0 | 3.65 | Strong design pattern, not directly Codex-compatible |
| Google Code Review Standard | normative input | 3.5 | 3.8 | 4.8 | 4.0 | 3.2 | 4.0 | 3.89 | Strong quality rubric |
| OWASP Secure Code Review Cheat Sheet | normative input | 3.5 | 4.6 | 4.7 | 4.3 | 3.8 | 4.5 | 4.19 | Security skepticism backbone |
| NIST SSDF | normative input | 3.2 | 4.2 | 4.8 | 3.8 | 4.2 | 4.4 | 4.00 | Policy/process guardrails |
| AWS Well-Architected | normative input | 3.2 | 4.1 | 4.6 | 4.0 | 3.7 | 4.0 | 3.84 | Architecture tradeoff lenses |

## Top Results by Use Case

### Immediate reusable assets

1. `code-review-master` (mandatory handoff target)
2. OpenAI `security-threat-model`
3. OpenAI `gh-fix-ci`
4. `enterprise-readiness`

### Best inputs for custom skeptical suite

1. Outfitter `simplify` pattern
2. OWASP Secure Code Review Cheat Sheet
3. NIST SSDF
4. AWS Well-Architected

## Recommendation

Use a custom Skeptiker suite (`skeptic-argument-quality`, `skeptic-complexity`, `skeptic-architecture`, `skeptic-coding`, `skeptic-security`, `skeptic-router`) as primary implementation.

Reuse existing skills via handoff instead of duplication:

- Mandatory: `$code-review-master` for non-trivial coding changes
- Optional security depth: `$security-threat-model`, `$security-audit`
- Optional CI evidence: `$gh-fix-ci`
