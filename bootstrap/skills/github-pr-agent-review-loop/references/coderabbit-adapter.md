# CodeRabbit Adapter

Bot login: `coderabbitai[bot]`.

## Trigger

Post a PR issue comment:

```text
@coderabbitai review
```

## Acknowledgement

The `Review triggered` comment is only an acknowledgement. It is not a review result and never means the loop is complete.

When checking for CodeRabbit state, avoid `gh pr view --json comments,reviews` and other broad all-body pulls. Use focused issue-comment, review, and review-comment queries filtered to `coderabbitai[bot]`, then fetch full bodies only for the latest current-round signals.

## Findings

CodeRabbit has findings when:

- The review state is `CHANGES_REQUESTED`.
- The review body contains `Actionable comments posted: N`.

CodeRabbit has no findings when:

- An issue comment contains `No actionable comments were generated in the recent review`, or
- A review state is `APPROVED`.

Ignore empty `COMMENTED` reviews as final results. They commonly represent individual thread replies or cleanup events.

## Thread Handling

For each finding:

1. Verify against current code.
2. Fix only still-valid findings.
3. Reply when a fix explanation, skip reason, or clarification is useful.
4. Do not manually resolve CodeRabbit conversations.

CodeRabbit resolves or confirms prior comments in later review rounds.

Reply examples:

```text
Fixed in abc1234: normalized quoted environment values before comparison. Verified with `bats tests/unit/test_migrate_env.bats`.
```

```text
Verified against current head and skipped: the referenced file was removed in the current diff.
```
