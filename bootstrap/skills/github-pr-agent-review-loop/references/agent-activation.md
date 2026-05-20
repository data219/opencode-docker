# Agent Activation

Classify each review agent before posting any re-review trigger. Do not bootstrap agents blindly just because the skill knows their trigger phrase.

## States

`active`: The agent has usable activity on the current PR, either automatically after first push, PR creation, ready-for-review, or from an earlier valid review round.

Signals:

- Bot issue comment, PR review, inline review comment, or bot reaction on the PR.
- Codex `### 💡 Codex Review`, inline findings, or `Codex Review: Didn't find any major issues`.
- CodeRabbit Summary, Walkthrough, Review Stack, `Actionable comments posted`, `No actionable comments were generated in the recent review`, or `APPROVED`.

`unknown/pending`: A trigger or automatic start signal exists, but there is only acknowledgement or in-progress activity. Keep polling within the timing window; do not treat it as clean.

Signals:

- CodeRabbit `Review triggered`.
- Bot `eyes` or similar acknowledgement reaction without a review result.
- In-progress wording without actionable or clean output.

`inactive`: No automatic activity from that agent appears after first push, PR creation, or ready-for-review, and there is no prior usable result on the PR. Do not trigger this agent later unless the user explicitly asks to activate it.

`unavailable/misconfigured`: The agent says it cannot run for this repo. Stop triggering it and report the setup blocker.

Signals:

- Codex replies with `To use Codex here, create an environment for this repo`.
- Any agent says repository setup, installation, permissions, or configuration are missing.

## Trigger Rules

- Trigger re-review only for `active` agents.
- Poll `unknown/pending` agents until a real result, unavailable signal, or timeout.
- If one agent is active and the other is inactive or unavailable, run the loop with the active agent only.
- Include inactive, pending-timeout, and unavailable states in the final report.
