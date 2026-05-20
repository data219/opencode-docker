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

## Scenario 4: Codex Active, CodeRabbit Never Appeared

Prompt:

```text
A new PR had automatic first-push activity from Codex only: Codex posted a review with findings. CodeRabbit has no bot comments, reviews, reactions, summary, walkthrough, or no-actionable signal on the PR. The user asks you to fix review-agent feedback and loop until clean. Which agents do you trigger after the fix?
```

Pass criteria:

- Classifies Codex as active.
- Classifies CodeRabbit as inactive.
- Triggers only `@codex review` after the fix.
- Reports that CodeRabbit was inactive instead of silently treating it as clean.

RED baseline observation:

- Failure observed: baseline would trigger both agents.
- Evidence sentence: baseline cited `Trigger @codex review and @coderabbitai review` and `Repeat until both agents report no findings`.
- Counter-rule added: classify agent activation before triggering; only active agents enter the loop.

## Scenario 5: CodeRabbit Active, Codex Setup Error

Prompt:

```text
A PR has automatic CodeRabbit walkthrough and later actionable comments. Codex is manually triggered once and replies: "To use Codex here, create an environment for this repo." After fixing CodeRabbit findings, should you trigger Codex again?
```

Pass criteria:

- Classifies CodeRabbit as active.
- Classifies Codex as unavailable/misconfigured.
- Does not trigger Codex again unless setup changes.
- Includes the Codex setup blocker in the final report.

RED baseline observation:

- Failure observed: baseline would keep waiting for or triggering both agents.
- Evidence sentence: baseline cited `poll every 2 minutes until both agents return real results` and `Repeat until both agents report no findings`.
- Counter-rule added: Codex setup-error responses make Codex unavailable for this PR.

## Scenario 6: Both Agents Automatically Active

Prompt:

```text
After first push, Codex posts a `### 💡 Codex Review` and CodeRabbit posts a walkthrough plus `Actionable comments posted: 2`. After fixing findings, which re-review triggers are posted?
```

Pass criteria:

- Classifies both agents as active.
- Posts separate `@codex review` and `@coderabbitai review` comments.
- Waits for real results from both active agents.

RED baseline observation:

- No failure observed.
- Evidence sentence: baseline already included both agents by default.
- Counter-rule confirmed: both agents stay in the loop when both are active.

## Scenario 7: CI Failing On Current Head

Prompt:

```text
After a review-fix commit, `gh pr view` reports current `headRefOid` abc123. `gh pr checks` for abc123 is failing, and `gh run view <run_id> --log` shows the failure is caused by the changed test fixture in this PR. What happens before agent re-review triggers?
```

Pass criteria:

- Matches CI state to current `headRefOid`.
- Inspects GitHub Actions logs.
- Classifies the failure as current-change.
- Fixes CI, verifies, commits, pushes, re-reads `headRefOid`, then triggers active agents.

RED baseline observation:

- Failure observed: baseline did not require per-round CI checks tied to `headRefOid` or log inspection.
- Evidence sentence: baseline relied only on `relevant checks` and `Run the smallest useful verification`.
- Counter-rule added: CI is checked every round and current-change failures are fixed before re-review triggers.

## Scenario 8: CI Failing External Or Unrelated

Prompt:

```text
Current-head checks fail, but logs show a third-party outage, runner infrastructure error, or an unrelated workflow failure not caused by the PR diff. Do you guess a code fix, ignore CI, or classify it?
```

Pass criteria:

- Uses logs or missing-log evidence before classification.
- Classifies external, transient, unrelated, or unclear.
- Does not invent a code fix.
- Reports the remaining CI risk or blocker.

RED baseline observation:

- Failure observed: baseline partially separated unrelated CI but did not require log-based classification or explicit escalation.
- Evidence sentence: baseline had `Treats unrelated CI as separate` but only generic `relevant checks`.
- Counter-rule added: classify failing CI from current-head evidence and logs; stop on unclear failures.

## Rationalization Table

| Excuse | Reality |
|---|---|
| "CodeRabbit acknowledged the trigger, so it is done." | The acknowledgement is not a review result. Wait for `APPROVED`, `No actionable comments`, or `Actionable comments posted`. |
| "Outdated Codex threads can just be resolved silently." | Comment with the reason first, then resolve. |
| "CodeRabbit threads should be resolved like Codex." | Do not manually resolve CodeRabbit; it handles prior comments in later rounds. |
| "Unrelated CI is failing, so fix it now." | Keep scope to review-agent findings unless the failure blocks the current fix. |
| "One clean agent is enough." | Completion requires every active agent to be clean in the latest relevant round. |
| "A previous clean CodeRabbit comment stays valid forever." | A newer actionable CodeRabbit `CHANGES_REQUESTED` review makes the loop current again. |
| "The skill knows both trigger phrases, so trigger both." | Trigger only agents classified active on this PR. |
| "Codex setup errors may resolve if triggered again." | Treat setup-required responses as unavailable until setup changes. |
| "CI is just a background signal." | Check CI every round against current `headRefOid` and classify failures before re-review. |

## Verification Results

| Scenario | Result | Evidence |
|---|---|---|
| 1 | PASS | Test agent protected unrelated edits, treated unrelated CI separately, resolved only Codex threads after replies, did not resolve CodeRabbit manually, committed and pushed fix batches, triggered both re-reviews, and looped until both agents were clean. |
| 2 | PASS | Test agent treated `Review triggered` as an acknowledgement, waited at least 6 minutes, then polled every 2 minutes until real results or timeout. |
| 3 | PASS | Test agent counted Codex no-major-issues and later CodeRabbit no-actionable as clean, ignored empty CodeRabbit `COMMENTED`, and did not resurrect stale earlier findings. |
| 4 | PASS | GREEN agent classified Codex as active and CodeRabbit as inactive, triggered only `@codex review`, and required reporting inactive CodeRabbit. |
| 5 | PASS | GREEN agent classified CodeRabbit as active and Codex as unavailable/misconfigured after the setup-error response, and did not trigger Codex again unless setup changes. |
| 6 | PASS | GREEN agent classified both automatic review agents as active, posted separate re-review comments, and waited for real results from both. |
| 7 | PASS | GREEN agent matched CI to current `headRefOid`, inspected logs, classified current-change failure, and required fix, verify, commit, push, head re-read, then active-agent triggers. |
| 8 | PASS | GREEN agent used logs or missing-log evidence, classified external/transient/unrelated/unclear failures, avoided guessed code fixes, and reported remaining CI risk. |
