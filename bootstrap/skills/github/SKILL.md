---
name: github
description: "Use when interacting with GitHub from command line: auth issues, repository operations, branch management, pull requests, issues, CI/CD, releases, organization management, API queries, or troubleshooting gh CLI errors."
metadata: {
  "nanobot": {
    "emoji": "🐙",
    "requires": {
      "bins": ["gh"],
      "env": ["GH_TOKEN"]
    },
    "install": [
      {
        "id": "brew",
        "kind": "brew",
        "formula": "gh",
        "bins": ["gh"],
        "label": "Install GitHub CLI (brew)"
      },
      {
        "id": "apt",
        "kind": "apt",
        "package": "gh",
        "bins": ["gh"],
        "label": "Install GitHub CLI (apt)"
      }
    ],
    "references": [
      {
        "file": "QUICK_REFERENCE.md",
        "description": "Quick reference for common gh CLI commands"
      },
      {
        "file": "BEST_PRACTICES.md",
        "description": "Best practices for GitHub workflows and gh CLI usage"
      }
    ]
  }
}
---

# GitHub CLI (gh)

## Quick Start

```bash
gh --version && gh auth status
gh auth login
gh repo list
gh pr create --title "Fix" --body "Fixes #42"
```

Full reference: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

## When to Use

Use for GitHub CLI interaction:
- Auth issues, token problems, permission errors
- Repository operations (create, clone, fork)
- Branch management, pull requests, issues
- CI/CD (runs, logs, workflows)
- Releases, organization management
- API queries (REST/GraphQL)
- Troubleshooting gh CLI errors

NOT for: Git operations (`git` CLI), local repo management.

## Authentication

```bash
gh auth login  # Browser auth (recommended)
gh auth login --with-token < token.txt  # CI/CD
gh auth login --refresh  # Refresh token
gh auth login --scopes repo,workflow  # Set scopes
gh ssh-key add ~/.ssh/id_ed25519 --title "My key"
```

## Core Workflows

### Repository
```bash
gh repo create my-repo --public
gh repo clone owner/repo
gh repo view owner/repo
```

### Pull Requests
```bash
gh pr list
gh pr create --title "Feature" --body "Description"
gh pr merge 123 --squash
gh pr checkout 123
```

### Issues
```bash
gh issue list --state open
gh issue create --title "Bug" --body "Steps..."
gh issue close 123
```

### CI/CD
```bash
gh run list --status failed
gh run view 456789 --log
gh run rerun 456789
```

### Releases
```bash
gh release create v1.0.0 --notes "Release notes"
gh release upload v1.0.0 ./dist/app.zip
```

### API
```bash
gh api /repos/:owner/:repo
gh api /user --jq '.login'
gh api graphql -f query='{ viewer { login } }'
```

## Troubleshooting

```bash
gh auth login  # Not logged in
gh auth login --refresh  # Token expired
gh auth login --scopes repo,workflow  # Insufficient scopes
gh --debug pr list  # Debug mode
gh --version && brew upgrade gh  # Update gh CLI
GH_DEBUG=1 gh <command>  # Debug crashes
gh config set -h  # Reset corrupted config
gh config set http_proxy http://proxy.example.com:8080  # Proxy
```

Full troubleshooting: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

## Best Practices

Security & productivity: [BEST_PRACTICES.md](BEST_PRACTICES.md)

**Security:** Use browser auth, NEVER type tokens literally. Use file input: `gh secret set API_TOKEN < secret.txt`

## Help

```bash
gh --help
gh pr --help
gh pr create --help  # All options
```

Complete reference: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
