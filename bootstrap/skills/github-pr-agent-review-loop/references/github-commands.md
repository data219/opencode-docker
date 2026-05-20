# GitHub Commands

## Auth And PR State

```bash
gh auth status
gh pr view --json number,url,title,state,headRefName,baseRefName,headRefOid,mergeStateStatus,statusCheckRollup
```

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

```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR=$(gh pr view --json number --jq '.number')
gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" --paginate
gh api "repos/$OWNER/$REPO/pulls/$PR/comments" --paginate
gh api "repos/$OWNER/$REPO/issues/$PR/comments" --paginate
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
          comments(first: 100) {
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
