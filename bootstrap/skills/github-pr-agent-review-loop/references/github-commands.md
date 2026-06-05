# GitHub Commands

## Auth And PR State

```bash
gh auth status
gh pr view --json number,url,title,state,headRefName,baseRefName,headRefOid,mergeStateStatus,statusCheckRollup --jq '{number,url,title,state,headRefName,baseRefName,headRefOid,mergeStateStatus,checks:[.statusCheckRollup[]? | {name,status:(.status // .state),conclusion:(.conclusion // ""),detailsUrl:(.detailsUrl // .link // "")}]}'
```

## Polling And Payload Guardrails

- Do not run sleeps longer than 30 seconds or multi-minute silent polling loops. For external reviewer or CI waits, poll with visible short checks and stop after the timing window with the exact next command to run.
- Do not use `gh pr view --json comments,reviews`, `gh pr view --json latestReviews,comments,reviews`, or other all-body pulls as the default review-loop state source.
- Prefer narrow `gh --json --jq` fields for PR and CI state, GraphQL `reviewThreads` for inline Codex threads, and focused REST endpoints for issue/review comments.
- Fetch full comment bodies only after narrowing to the current active-agent signals and matching the current `headRefOid`.

## CI State

Match checks to the current `headRefOid`.

```bash
PR=$(gh pr view --json number --jq '.number')
HEAD_SHA=$(gh pr view --json headRefOid --jq '.headRefOid')
gh pr checks "$PR" --json name,state,startedAt,completedAt,link,bucket
gh run list --branch "$(gh pr view --json headRefName --jq '.headRefName')" --json databaseId,headSha,status,conclusion,workflowName,displayTitle,createdAt,updatedAt
RUN_ID=$(gh run list --branch "$(gh pr view --json headRefName --jq '.headRefName')" --json databaseId,headSha,status,conclusion --jq ".[] | select(.headSha == \"$HEAD_SHA\" and (.conclusion == \"failure\" or .status != \"completed\")) | .databaseId" | head -n 1)
gh run view "$RUN_ID" --log
```

## REST Sources

Use REST when issue comments or review summaries are needed. Filter by bot login, timestamp, and current review round before inspecting large bodies.

```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR=$(gh pr view --json number --jq '.number')
HEAD_SHA=$(gh pr view --json headRefOid --jq '.headRefOid')
BOT_LOGIN="codex-bot"  # or other bot login
REVIEW_ROUND="R1"      # current review round
REVIEW_ROUND_START=$(date -u +"%Y-%m-%dT%H:%M:%SZ")  # set at start of review round

# Filter reviews by bot login and timestamp before inspecting bodies
gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" --paginate --jq ".[] | select(.user.login == \"$BOT_LOGIN\" and (.body | contains(\"$REVIEW_ROUND\")) and .submitted_at > \"$REVIEW_ROUND_START\")"

# Filter inline comments by bot login, commit SHA, and review round
gh api "repos/$OWNER/$REPO/pulls/$PR/comments" --paginate --jq ".[] | select(.user.login == \"$BOT_LOGIN\" and .commit_id == \"$HEAD_SHA\" and (.body | contains(\"$REVIEW_ROUND\")))"

# Filter issue comments by bot login, timestamp, and review round
gh api "repos/$OWNER/$REPO/issues/$PR/comments" --paginate --jq ".[] | select(.user.login == \"$BOT_LOGIN\" and (.body | contains(\"$REVIEW_ROUND\")) and (.created_at > \"$REVIEW_ROUND_START\"))"
```

## Codex Review Thread Query

```graphql
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      id
      number
      headRefOid
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          diffSide
          comments(first: 20) {
            nodes {
              id
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}
```

## Codex Reply Mutation

```graphql
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { id url }
  }
}
```

## Codex Resolve Mutation

```graphql
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { id isResolved }
  }
}
```

## Trigger Re-Reviews

Prefer separate comments:

```bash
PR=$(gh pr view --json number --jq '.number')
gh pr comment "$PR" --body '@codex review'        # only when Codex is active
gh pr comment "$PR" --body '@coderabbitai review' # only when CodeRabbit is active
```

## Git Gates

```bash
git status --short
git diff --check
git push
```
