# CI Handling

CI is part of every review round. Match all check decisions to the current `headRefOid`; stale green or red checks from older commits do not prove the current PR state.

## Required Checks

1. Read `headRefOid`, `statusCheckRollup`, and `mergeStateStatus`.
2. Inspect `gh pr checks <pr> --json ...` for the same head SHA when available.
3. For failing GitHub Actions runs, inspect logs with `gh run view <run_id> --log`.
4. Classify each failure before triggering agent re-reviews.

## Classifications

`current-change`: The failure is caused by the review fix or current PR diff. Fix it in the same round, run focused verification, commit, push, then trigger active-agent re-reviews.

`external`: Infrastructure, service outage, quota, credentials, or unavailable dependency outside the PR. Do not guess a code fix. Report it as blocking or retryable evidence.

`transient`: Flake, runner failure, timeout, or network issue with no code evidence. Retry only when that is a normal project practice; otherwise report the uncertainty.

`unrelated`: Existing workflow or branch-base problem not caused by the PR diff. Keep it separate unless it blocks merge and the user asks to handle it.

`unclear`: Logs are unavailable or do not identify a cause. Stop before inventing a fix; report what evidence is missing.

## Ordering

- Fix current-change CI failures before posting re-review triggers.
- If a fix push changes `headRefOid`, restart the round from live PR state.
- Do not claim completion unless active-agent results and CI classification both correspond to the final `headRefOid`.
