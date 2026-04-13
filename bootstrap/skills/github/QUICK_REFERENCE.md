# GitHub CLI (gh) - Quick Reference

Quick reference for common gh CLI commands. For comprehensive documentation, see [SKILL.md](SKILL.md).

## Authentication

```bash
gh auth status          # Check auth status
gh auth login           # Login to GitHub
gh auth logout          # Logout
gh auth setup-git       # Configure git
```

## Repositories

```bash
gh repo list            # List repos
gh repo create name     # Create repo
gh repo clone owner/repo # Clone repo
gh repo view            # View repo info
gh repo delete owner/repo # Delete repo
```

## Branches

```bash
gh branch list          # List branches
gh branch create name   # Create branch
gh branch delete name   # Delete branch
gh diff branch1..branch2 # Compare branches
```

## Pull Requests

```bash
gh pr list              # List PRs
gh pr create            # Create PR
gh pr view 123          # View PR
gh pr merge 123         # Merge PR
gh pr checkout 123      # Checkout PR
gh pr review 123        # Review PR
```

## Issues

```bash
gh issue list           # List issues
gh issue create         # Create issue
gh issue view 123       # View issue
gh issue close 123      # Close issue
gh issue comment 123    # Comment on issue
```

## CI/CD (GitHub Actions)

```bash
gh run list             # List workflow runs
gh run view 456789      # View run details
gh run rerun 456789     # Rerun failed jobs
gh run cancel 456789    # Cancel run
gh workflow list        # List workflows
gh pr checks 123        # Check PR CI status
```

## Releases

```bash
gh release list         # List releases
gh release create v1.0.0 # Create release
gh release upload v1.0.0 file.zip # Upload asset
gh release download v1.0.0 # Download assets
```

## Organizations

```bash
gh org list             # List organizations
gh org view org-name    # View organization
gh repo list org-name   # List org repos
```

## API

```bash
gh api /user            # API request
gh api /repos/:owner/:repo/issues -f title="New issue" # POST
gh api --jq '.login'    # Filter with jq
```

## Troubleshooting

```bash
gh --verbose command    # Enable verbose output
gh config               # View configuration
gh --help               # Get help
gh command --help       # Get command help
```

## Common Patterns

### Get latest tag
```bash
gh release list --limit 1 --json tagName --jq '.[0].tagName'
```

### Get default branch
```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

### Get user email
```bash
gh api /user --jq '.email'
```

### Count issues
```bash
gh issue list --count
```
