# AtlCLI Command Reference

Snapshot date: 2026-03-31
Snapshot CLI version: `atlcli v0.14.0`
Confidence: best-effort exhaustive for core documented commands at snapshot date; plugin/feature-flag commands may vary and web crawl inputs are time-dependent.
Role: command appendix. Behavioral guardrails live in [SKILL.md](./SKILL.md).

## Normative Policy Pointer

Do not treat this file as normative policy text. Required safety and confirmation rules are defined in [SKILL.md](./SKILL.md).

Catalog notation:
- Entries are command signatures for discovery/grouping only.
- Do not execute these lines as-is; apply safety gates from [SKILL.md](./SKILL.md).

## Verification Evidence

Evidence artifacts committed in `artifacts/`:
- `artifacts/atlcli-version-2026-03-31.txt`
- `artifacts/atlcli-help-2026-03-31.txt`
- `artifacts/sitemap-index-2026-03-31.xml`
- `artifacts/sitemap-0-2026-03-31.xml`
- `artifacts/doc-crawl-notes-2026-03-31.md`
- `artifacts/doc-urls-2026-03-31.txt`
- `artifacts/extracted-commands-2026-03-31.txt`
- `artifacts/extract-run-2026-03-31.txt`
- `artifacts/crawl-manifest-2026-03-31.tsv`
- `artifacts/sitemap-hashes-2026-03-31.tsv`
- `artifacts/extract-meta-2026-03-31.txt`

Reproduction commands:

```bash
SKILL_DIR="/home/jan/.dotfiles/.agents/skills/atlcli"
TAG="2026-03-31"
atlcli --version > "$SKILL_DIR/artifacts/atlcli-version-$TAG.txt"
atlcli --help > "$SKILL_DIR/artifacts/atlcli-help-$TAG.txt"
curl -fsSL https://atlcli.sh/sitemap-index.xml > "$SKILL_DIR/artifacts/sitemap-index-$TAG.xml"
curl -fsSL https://atlcli.sh/sitemap-0.xml > "$SKILL_DIR/artifacts/sitemap-0-$TAG.xml"
$SKILL_DIR/scripts/extract_doc_commands.py "$SKILL_DIR/artifacts" --tag "$TAG" > "$SKILL_DIR/artifacts/extract-run-$TAG.txt"
```

`extract_doc_commands.py` is strict by default (non-zero exit on crawl errors). Use `--allow-partial` only for exploratory/debug runs.

## Global

```bash
atlcli --version
atlcli version
atlcli --profile <name> update
atlcli doctor
atlcli completion
atlcli completion bash
atlcli completion zsh
```

Common global options:
- `--profile <name>`
- `--json`
- `--no-log`
- `--help`

## Authentication (`auth`)

```bash
atlcli --profile <name> auth init
atlcli --profile <name> auth login
atlcli auth status
atlcli auth list
atlcli --profile <name> auth switch
atlcli --profile <name> auth rename
atlcli --profile <name> auth logout
atlcli --profile <name> auth delete
```

## Configuration (`config`, `flag`, `log`, `plugin`)

```bash
atlcli config list
atlcli config get
atlcli --profile <name> config set
atlcli --profile <name> config unset

atlcli flag list
atlcli flag ls
atlcli flag get
atlcli --profile <name> flag set
atlcli --profile <name> flag unset
atlcli --profile <name> flag rm

atlcli log list
atlcli log show
atlcli log tail
atlcli --profile <name> log clear

atlcli plugin list
atlcli --profile <name> plugin install
atlcli --profile <name> plugin enable
atlcli --profile <name> plugin disable
atlcli --profile <name> plugin remove
```

## Jira

### Core entry points

```bash
atlcli jira
atlcli jira me
atlcli jira my
atlcli jira search
atlcli --profile <name> jira import
atlcli --profile <name> jira export
atlcli --profile <name> jira watch
atlcli jira unwatch
atlcli jira watchers
```

### Issues

```bash
atlcli jira issue
atlcli jira issue get
atlcli --profile <name> jira issue create
atlcli --profile <name> jira issue update
atlcli --profile <name> jira issue delete
atlcli --profile <name> jira issue assign
atlcli --profile <name> jira issue transition
atlcli jira issue transitions
atlcli --profile <name> jira issue comment
atlcli --profile <name> jira issue link
atlcli --profile <name> jira issue attach
atlcli jira issue attachments
atlcli jira issue attachment download
atlcli --profile <name> jira issue attachment delete
atlcli jira issue open
atlcli jira issue pages
atlcli --profile <name> jira issue link-page
atlcli --profile <name> jira issue unlink-page
```

### Projects, boards, sprints

```bash
atlcli jira project list
atlcli jira project get
atlcli jira project types

atlcli jira board list
atlcli jira board get
atlcli jira board issues
atlcli jira board backlog

atlcli jira sprint list
atlcli jira sprint get
atlcli --profile <name> jira sprint create
atlcli --profile <name> jira sprint start
atlcli --profile <name> jira sprint close
atlcli --profile <name> jira sprint delete
atlcli --profile <name> jira sprint add
atlcli --profile <name> jira sprint remove
atlcli jira sprint report
```

### Epics, subtasks, components, versions

```bash
atlcli jira epic list
atlcli jira epic get
atlcli --profile <name> jira epic create
atlcli --profile <name> jira epic add
atlcli --profile <name> jira epic remove
atlcli jira epic issues
atlcli jira epic progress

atlcli jira subtask list
atlcli --profile <name> jira subtask create

atlcli jira component list
atlcli --profile <name> jira component create
atlcli --profile <name> jira component update
atlcli --profile <name> jira component delete

atlcli jira version list
atlcli --profile <name> jira version create
atlcli --profile <name> jira version update
atlcli --profile <name> jira version release
atlcli --profile <name> jira version delete
```

### Worklogs and timer

```bash
atlcli --profile <name> jira worklog add
atlcli jira worklog list
atlcli --profile <name> jira worklog update
atlcli --profile <name> jira worklog delete
atlcli jira worklog report
atlcli --profile <name> jira worklog timer start
atlcli --profile <name> jira worklog timer stop
atlcli jira worklog timer status
atlcli jira worklog timer cancel
```

### Fields, filters, templates, analytics

```bash
atlcli jira field list
atlcli jira field get
atlcli jira field search
atlcli jira field options

atlcli jira filter list
atlcli jira filter get
atlcli --profile <name> jira filter create
atlcli --profile <name> jira filter update
atlcli --profile <name> jira filter delete
atlcli jira filter run
atlcli --profile <name> jira filter share

atlcli jira template list
atlcli jira template get
atlcli --profile <name> jira template save
atlcli --profile <name> jira template apply
atlcli --profile <name> jira template delete
atlcli --profile <name> jira template import
atlcli --profile <name> jira template export

atlcli jira analyze velocity
atlcli jira analyze burndown
atlcli jira analyze predictability
```

### Bulk operations and webhooks

```bash
atlcli --profile <name> jira bulk transition
atlcli --profile <name> jira bulk edit
atlcli --profile <name> jira bulk delete
atlcli --profile <name> jira bulk move
atlcli --profile <name> jira bulk label add
atlcli --profile <name> jira bulk label remove

atlcli jira webhook serve
atlcli jira webhook list
atlcli jira webhook register
atlcli jira webhook refresh
atlcli --profile <name> jira webhook delete
```

## Confluence / Wiki

### Core entry points

```bash
atlcli wiki
atlcli wiki my
atlcli wiki recent
atlcli wiki search
atlcli --profile <name> wiki export
```

### Spaces

```bash
atlcli wiki space list
atlcli wiki space get
atlcli --profile <name> wiki space create
```

### Pages

```bash
atlcli wiki page list
atlcli wiki page get
atlcli --profile <name> wiki page create
atlcli --profile <name> wiki page update
atlcli --profile <name> wiki page delete
atlcli wiki page open
atlcli --profile <name> wiki page copy
atlcli --profile <name> wiki page move
atlcli wiki page diff
atlcli wiki page children
atlcli wiki page history
atlcli --profile <name> wiki page archive
atlcli --profile <name> wiki page restore
atlcli --profile <name> wiki page convert
atlcli wiki page issues
atlcli wiki page sort
atlcli --profile <name> wiki page link-issue
atlcli --profile <name> wiki page unlink-issue
```

### Page labels

```bash
atlcli wiki page label list
atlcli --profile <name> wiki page label add
atlcli --profile <name> wiki page label remove
```

### Page comments (including inline comments)

```bash
atlcli wiki page comments list
atlcli --profile <name> wiki page comments add
atlcli --profile <name> wiki page comments add-inline
atlcli --profile <name> wiki page comments update
atlcli wiki page comments reply
atlcli --profile <name> wiki page comments delete
atlcli --profile <name> wiki page comments resolve
atlcli --profile <name> wiki page comments reopen
```

Inline workflow details are documented in [SKILL.md](./SKILL.md).

### Docs sync

```bash
atlcli --profile <name> wiki docs init
atlcli wiki docs pull
atlcli wiki docs status
atlcli wiki docs check
atlcli wiki docs diff
atlcli --profile <name> wiki docs push
atlcli --profile <name> wiki docs resolve
atlcli --profile <name> wiki docs sync
atlcli --profile <name> wiki docs watch
atlcli --profile <name> wiki docs convert
atlcli wiki docs preview
atlcli --profile <name> wiki docs add
atlcli --profile <name> wiki docs commit
atlcli wiki docs ignore-check
```

### Docs templates

```bash
atlcli wiki docs template list
atlcli wiki docs template get
atlcli --profile <name> wiki docs template save
atlcli --profile <name> wiki docs template apply
atlcli --profile <name> wiki docs template delete
atlcli --profile <name> wiki docs template import
atlcli --profile <name> wiki docs template export
```

### Wiki templates

```bash
atlcli wiki template list
atlcli wiki template show
atlcli --profile <name> wiki template create
atlcli wiki template edit
atlcli --profile <name> wiki template update
atlcli --profile <name> wiki template copy
atlcli --profile <name> wiki template rename
atlcli --profile <name> wiki template delete
atlcli wiki template render
atlcli wiki template validate
atlcli --profile <name> wiki template init
atlcli --profile <name> wiki template import
atlcli --profile <name> wiki template export
```

## Wiki audit

```bash
atlcli audit wiki
```

Documented audit check modes include:
- `--all`
- `--stale-high`, `--stale-medium`, `--stale-low`
- `--orphans`
- `--broken-links`
- `--single-contributor`
- `--inactive-contributors`
- `--external-links`
- `--check-external`
- `--missing-label`
- `--restricted`
- `--drafts`
- `--archived`
- `--high-churn`
- `--under-page`
- `--folders`
- `--include-remote`
- `--refresh-users`
- `--rebuild-graph`
- `--export-graph`
- `--json`
- `--markdown`
- `--fix`, `--dry-run`, `--fix-label`

## Optional / plugin-provided commands seen in docs

```bash
atlcli git ...
atlcli webhook ...
atlcli hello
atlcli helloworld
```

Provenance:
- CLI reference examples: [https://atlcli.sh/reference/cli-commands/](https://atlcli.sh/reference/cli-commands/)
- Plugin docs section: [https://atlcli.sh/plugins/](https://atlcli.sh/plugins/)
- Validate availability locally before use: `atlcli --help` and `atlcli plugin list`

## Drift Control

- Rebuild this file whenever AtlCLI minor version changes or docs add/remove command families.
- Keep snapshot date + version in header current.
- Re-run reproduction commands and refresh `artifacts/` evidence files.
