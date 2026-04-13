# RED Scenario: Inline Comment Syntax Missing

Date: 2026-03-31

## Baseline prompt

"Use atlcli to add an inline Confluence comment for the third occurrence of a repeated phrase."

## Baseline failure observed (before fix)

Recorded transcript:
- `artifacts/red-scenario-inline-comments.transcript.txt`
- `artifacts/baseline-pre-fix-skill-snippets-2026-03-31.txt`
- `artifacts/baseline-pre-fix-skill-snippets-2026-03-31.sha256`

Verification method:
```bash
sha256sum -c /home/jan/.dotfiles/.agents/skills/atlcli/artifacts/baseline-pre-fix-skill-snippets-2026-03-31.sha256
```

Observed failure:
- No inline comment workflow (`add-inline`, `--selection`, `--match-index`, `resolve --type inline`) in the baseline segment.

## Failure impact

- Agent can produce incorrect/ambiguous comment commands.
- Repeated-text selections can target wrong occurrence.
