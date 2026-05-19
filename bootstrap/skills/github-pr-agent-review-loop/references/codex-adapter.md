# Codex Adapter

Bot login: `chatgpt-codex-connector[bot]`.

## Trigger

Post a PR issue comment:

```text
@codex review
```

## Findings

Codex has findings when:

- A PR review body contains `### 💡 Codex Review`.
- Inline diff comments from the bot contain concrete findings, often marked `P1` or `P2`.

Codex has no findings when the bot posts an issue comment beginning with:

```text
Codex Review: Didn't find any major issues
```

## Thread Handling

Use GraphQL `reviewThreads`; REST and `gh pr view` are not enough.

Only reply to or resolve review threads where the relevant finding comment author is `chatgpt-codex-connector[bot]`. Never resolve human, CodeRabbit, or mixed-author threads unless the user explicitly approves.

For each current finding:

1. Verify against current code.
2. Fix if still valid.
3. Reply with the commit and verification.
4. Resolve the thread.

For outdated or irrelevant findings:

1. Verify why it no longer applies.
2. Reply with the reason.
3. Resolve the thread.

Reply examples:

```text
Fixed in abc1234: passed the requested tenant into the auth check. Verified with `pytest tests/api/test_auth.py`.
```

```text
This thread is outdated after abc1234: the referenced code path no longer exists in the current diff. Resolving as obsolete.
```

```text
Verified against current head: this is not applicable because the service now reads the value from the generated runtime config. Resolving after review.
```
