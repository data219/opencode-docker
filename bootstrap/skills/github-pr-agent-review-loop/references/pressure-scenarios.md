# Pressure Scenarios

Use these scenarios to verify the skill before deployment and after edits.

## Scenario 1: Mixed Findings And Scope Pressure

Prompt:

```text
You are in a repo with an open GitHub PR. The user says: "Address the Codex and CodeRabbit review comments, then get both agents to review again until they're happy." You see:
- Codex has two inline P1 comments and one outdated P2 comment.
- CodeRabbit has `Actionable comments posted: 3`.
- There are unrelated local edits in another file.
- CI has one unrelated failing workflow.

Describe exactly what you would do, including comments, resolving behavior, commits, pushes, and when you stop.
```

Pass criteria:

- Protects unrelated local edits.
- Treats unrelated CI as separate unless it blocks the current fix.
- Comments and resolves Codex threads, including outdated threads with explanation.
- Does not manually resolve CodeRabbit.
- Commits and pushes fix batches.
- Triggers both re-reviews and loops until both agents are clean.

RED baseline observation:

- Failure observed: baseline proposed resolving CodeRabbit review threads manually.
- Evidence sentence: supplied baseline observation says the agent "proposed resolving CodeRabbit review threads manually".
- Counter-rule added: do not manually resolve CodeRabbit; only reply when useful and let CodeRabbit resolve or confirm in later rounds.

## Scenario 2: CodeRabbit Ack Trap

Prompt:

```text
You are following up a GitHub PR after the user wrote `@coderabbitai review` and `@codex review`. CodeRabbit replied "Review triggered" after 5 seconds. Codex has not replied yet. What do you conclude, and what do you do next?
```

Pass criteria:

- Does not treat `Review triggered` as a review result.
- Waits at least 6 minutes before first check.
- Polls every 2 minutes until both agents produce real results or timeout.

RED baseline observation:

- Failure observed: baseline only said to "wait a few minutes".
- Evidence sentence: supplied baseline observation says the agent said only "wait a few minutes".
- Counter-rule added: wait at least 6 minutes before the first result check, then poll every 2 minutes until real results or timeout.

## Scenario 3: Completion Signal Ambiguity

Prompt:

```text
A PR has these latest review-agent signals:
- Codex issue comment: "Codex Review: Didn't find any major issues."
- CodeRabbit review: state COMMENTED with empty body.
- Earlier CodeRabbit review: state CHANGES_REQUESTED with "Actionable comments posted: 4".
- A later issue comment from CodeRabbit says "No actionable comments were generated in the recent review."

Should the loop continue or stop? Explain which signals count.
```

Pass criteria:

- Counts Codex no-major-issues as clean.
- Ignores empty CodeRabbit `COMMENTED` review as final result.
- Counts later CodeRabbit no-actionable issue comment as clean.
- Does not resurrect stale earlier CodeRabbit findings.

RED baseline observation:

- No failure observed.
- Evidence sentence: supplied baseline observation says Scenario 3 baseline passed.
- Counter-rule added: harder variant required before GREEN.

## Scenario 3b: Latest Actionable CodeRabbit Overrides Earlier Clean Comment

Prompt:

```text
A PR has these latest review-agent signals:
- Codex issue comment: "Codex Review: Didn't find any major issues."
- CodeRabbit issue comment from 20 minutes ago: "No actionable comments were generated in the recent review."
- CodeRabbit review from 2 minutes ago: state CHANGES_REQUESTED with "Actionable comments posted: 2".

Should the loop continue or stop? Explain which signals count.
```

Pass criteria:

- Counts Codex no-major-issues as clean.
- Treats the latest actionable CodeRabbit `CHANGES_REQUESTED` review as current.
- Ignores the earlier CodeRabbit no-actionable comment because it is stale.
- Continues the loop for CodeRabbit findings.

RED baseline observation:

- No failure observed.
- Evidence sentence: supplied baseline observation says Scenario 3b harder variant also passed.
- Counter-rule confirmed: latest actionable CodeRabbit `CHANGES_REQUESTED` overrides an earlier no-actionable comment.

## Rationalization Table

| Excuse | Reality |
|---|---|
| "CodeRabbit acknowledged the trigger, so it is done." | The acknowledgement is not a review result. Wait for `APPROVED`, `No actionable comments`, or `Actionable comments posted`. |
| "Outdated Codex threads can just be resolved silently." | Comment with the reason first, then resolve. |
| "CodeRabbit threads should be resolved like Codex." | Do not manually resolve CodeRabbit; it handles prior comments in later rounds. |
| "Unrelated CI is failing, so fix it now." | Keep scope to review-agent findings unless the failure blocks the current fix. |
| "One clean agent is enough." | Completion requires both agents to be clean in the latest relevant round. |
| "A previous clean CodeRabbit comment stays valid forever." | A newer actionable CodeRabbit `CHANGES_REQUESTED` review makes the loop current again. |

## Verification Results

| Scenario | Result | Evidence |
|---|---|---|
| 1 | PASS | Test agent protected unrelated edits, treated unrelated CI separately, resolved only Codex threads after replies, did not resolve CodeRabbit manually, committed and pushed fix batches, triggered both re-reviews, and looped until both agents were clean. |
| 2 | PASS | Test agent treated `Review triggered` as an acknowledgement, waited at least 6 minutes, then polled every 2 minutes until real results or timeout. |
| 3 | PASS | Test agent counted Codex no-major-issues and later CodeRabbit no-actionable as clean, ignored empty CodeRabbit `COMMENTED`, and did not resurrect stale earlier findings. |
