# GitHub CLI (gh) - Best Practices

Best practices for GitHub workflows and gh CLI usage. For comprehensive documentation, see [SKILL.md](SKILL.md).

## Authentication

✅ **DO:**
- Use browser authentication for interactive sessions
- Use `gh auth setup-git` for seamless git operations
- Re-authenticate if you see permission errors
- Use scoped auth when needed: `gh auth login --scopes repo,workflow`

❌ **DON'T:**
- Hardcode tokens in scripts (use `gh auth token` if needed)
- Share authentication tokens
- Use global-scope tokens if you only need read access

## Repository Workflows

✅ **DO:**
- Create repos from current directory: `gh repo create --source=.`
- Use `--private` for sensitive projects
- Enable issues and wiki: `gh repo edit --enable-issues --enable-wiki`
- Fork before contributing: `gh repo fork --clone --remote-name upstream`

❌ **DON'T:**
- Delete repositories without backup (`gh repo delete` is permanent)
- Archive active repos (use for truly inactive projects only)

## Pull Request Best Practices

✅ **DO:**
- Use PR templates for consistent descriptions
- Request specific reviewers: `gh pr create --reviewer username`
- Link issues: `gh pr create --body "Fixes #42"`
- Use `--squash` for clean history: `gh pr merge --squash`
- Delete merged branches: `gh pr merge --delete-branch`

❌ **DON'T:**
- Merge PRs without review (for production code)
- Skip CI checks (ensure all checks pass before merging)
- Use unclear PR titles/descriptions

## Issue Management

✅ **DO:**
- Use labels for categorization: `gh issue create --label bug,high-priority`
- Assign owners: `gh issue create --assignee username`
- Link related issues in comments
- Close issues with reference to PR: `gh issue close --comment "Fixed in #456"`

❌ **DON'T:**
- Create duplicate issues (search first: `gh search issues`)
- Leave issues unresolved without comment

## CI/CD & Workflows

✅ **DO:**
- Monitor CI status: `gh pr checks 123`
- Rerun only failed jobs: `gh run rerun --failed`
- Use workflow names consistently
- Keep workflow runs history (don't delete unless necessary)

❌ **DON'T:**
- Ignore failed CI checks
- Delete workflow runs indiscriminately
- Run workflows excessively (watch rate limits)

## Release Management

✅ **DO:**
- Use semantic versioning (v1.0.0, v2.1.3, etc.)
- Write detailed release notes
- Upload artifacts for users: `gh release upload v1.0.0 ./dist/app.zip`
- Mark pre-releases appropriately: `gh release create v2.0.0-beta --prerelease`

❌ **DON'T:**
- Release without testing
- Delete old releases (keep for history)
- Release without notes

## API Usage

✅ **DO:**
- Use `--paginate` for large result sets
- Filter with jq: `gh api --jq '...'`
- Handle rate limits gracefully
- Check authentication before API calls: `gh auth status`

❌ **DON'T:**
- Make excessive API calls (cache results)
- Ignore rate limit responses
- Hardcode API endpoints (use variables)

## Productivity Tips

**Keyboard shortcuts:**
- Use `--web` to open in browser: `gh pr view --web`
- Use `--json` for scripting: `gh pr list --json ...`
- Use `--jq` for filtering: `gh api --jq '...'`

**Aliases:**
Create bash aliases for frequently used commands:
```bash
alias ghl='gh pr list'
alias ghv='gh pr view'
alias ghm='gh pr merge --squash'
```

**Tab completion:**
Enable gh tab completion:
```bash
gh completion -s zsh > ~/.zsh/completions/_gh
```

## Security Best Practices

✅ **DO:**
- Use `gh auth status` to verify authentication
- Use minimal scopes for auth: `gh auth login --scopes repo`
- Enable 2FA on your GitHub account
- Review SSH keys regularly: `gh ssh-key list`
- Use `--private` for sensitive repos

❌ **DON'T:**
- Store secrets in repo (use GitHub Secrets)
- Share PATs or tokens
- Use public repos for private code
- Commit `.env` files with credentials

## Workflow Automation

**Scripting with gh:**
Use JSON output for scripts:
```bash
#!/bin/bash
# Get all open PRs and print titles
gh pr list --state open --json title --jq '.[].title'
```

**CI Integration:**
Use gh in GitHub Actions:
```yaml
- name: Comment on PR
  run: gh pr comment ${{ github.event.number }} --body "Build successful"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Performance Tips

- Use `--limit` for large lists: `gh pr list --limit 20`
- Filter early: `gh issue list --label bug` instead of filtering locally
- Cache API responses in scripts
- Use `--jq` for filtering instead of post-processing

## Common Patterns

**Get latest tag:**
```bash
gh release list --limit 1 --json tagName --jq '.[0].tagName'
```

**Get default branch:**
```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

**Get user email:**
```bash
gh api /user --jq '.email'
```

**Count issues:**
```bash
gh issue list --count
```

## Learning Resources

- Official gh CLI docs: https://cli.github.com/manual/
- GitHub API docs: https://docs.github.com/en/rest
- GraphQL Explorer: https://docs.github.com/en/graphql/overview/explorer
