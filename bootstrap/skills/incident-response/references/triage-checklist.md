# Triage Checklist

## 0-15 Minutes (Contain + Frame)
- Declare incident commander and scribe.
- Record start time, impacted customer journeys, and severity hypothesis.
- Run triage order: impact -> metrics -> logs -> traces/events -> errors -> mitigation.
- Open hypothesis ledger (at least two competing hypotheses).

## 15-30 Minutes (Correlate + Decide)
- Prometheus/Grafana prompts:
  - "Which services changed error/latency/saturation since T0?"
  - "What changed per release, zone, tenant, or endpoint?"
- InfluxDB/Telegraf prompts:
  - "Which host/container signals diverged from baseline at incident onset?"
- ELK prompts:
  - "Which log patterns co-occur with T0 and affected routes?"
  - "Do failures cluster by dependency, region, or deployment version?"
- Sentry prompts:
  - "Which exception groups spiked at T0 and map to impacted users?"
  - "Which release/env tags correlate with spike onset?"
- Uptime Kuma prompts:
  - "Which checks fail by region and how intermittent is failure?"
  - "What is current external availability by customer-facing endpoint?"

## 30-60 Minutes (Mitigate + Reassess)
- Choose smallest reversible mitigation.
- Safety checks before action:
  - rollback command/runbook identified,
  - approver recorded,
  - blast-radius reassessment documented.
- After mitigation, re-score severity and reprioritize across active incidents.

## Conflicting Signals Tie-Breakers
- Prefer signals closest to customer impact over internal-only signals.
- Prefer time-aligned cross-source correlation over single-source spikes.
- Require two-source corroboration before root-cause declaration.
- If conflict persists, run one targeted experiment (feature flag, canary rollback, traffic shift) and measure.

## Degraded Observability fallback
- If a tool is unavailable, mark degraded-observability mode and continue.
- fallback order:
  - Sentry down -> metrics + logs + deployment events.
  - ELK delayed -> metrics + uptime checks + tracing/events.
  - Metrics unavailable -> uptime checks + logs + Sentry.
- Escalate to platform/on-call observability owner if data freshness blocks safe mitigation >15 min.

## Communication Cadence
- Every 15 minutes: status, current hypothesis leader, active risks, next action.
- At stabilization: unresolved unknowns, follow-up owner, and prevention tasks.
