---
name: incident-response
description: Use when an alert, outage, error spike, latency surge, or telemetry anomaly needs fast multi-tool incident triage and safe mitigation decisions.
---

# Observability Incident Response

## Purpose
Stabilize customer impact first, form testable hypotheses from multiple observability sources, and mitigate safely under time pressure.

## Workflow (deterministic order)
1. Impact: define affected users, surfaces, and current blast radius.
2. Metrics: confirm onset time, slope, and affected services (Prometheus/Grafana/InfluxDB).
3. Logs: correlate by time window, deployment marker, and component boundaries (ELK).
4. Traces/events: check dependency failures, saturation, and recent changes.
5. Errors: validate exception families and release correlation (Sentry).
6. Mitigation: pick the smallest reversible action with explicit rollback.

Keep a hypothesis ledger with: hypothesis, evidence for/against, confidence, next check.

## Guardrails
- Do not close incident on symptom recovery alone.
- Do not declare root cause without two-source corroboration.
- If a mitigation changes traffic/config, perform safety checks first: rollback path, owner approval, and blast-radius reassessment.

## Multi-Incident Prioritization
When incidents compete, prioritize by:
1. User harm and revenue impact.
2. Blast radius growth rate.
3. Time-to-irreversible-damage risk.
4. Confidence that a mitigation is safe and reversible.

Re-rank after each mitigation or major signal change.

## Fallback and Escalation
If any primary tool is down/lagged, continue with remaining sources and state confidence explicitly.
- Missing Sentry: rely on metrics/log correlation + deployment timeline.
- Delayed ELK: use metrics, Uptime Kuma checks, and service-level health probes.
- Missing metrics: use Uptime Kuma + logs + recent change events.

Escalate immediately when:
- `critical_miss_count` risk is non-zero,
- no safe mitigation is available within 30 minutes,
- evidence remains conflicting after one full triage pass.

Use the operational checklist: `references/triage-checklist.md`.
