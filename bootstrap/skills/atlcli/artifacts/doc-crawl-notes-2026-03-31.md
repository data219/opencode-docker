# AtlCLI Doc Crawl Notes (2026-03-31)

## Scope

- Source sitemaps:
  - `https://atlcli.sh/sitemap-index.xml`
  - `https://atlcli.sh/sitemap-0.xml`
- Crawl coverage:
  - all URLs from the sitemap (`artifacts/doc-urls-2026-03-31.txt`)
- Focus verification pages:
  - `https://atlcli.sh/reference/cli-commands/`
  - `https://atlcli.sh/confluence/comments/`
- Local CLI checks:
  - `atlcli --version` => `atlcli v0.14.0`
  - `atlcli --help`

## Repeatable extraction (time-dependent)

```bash
SKILL_DIR="/home/jan/.dotfiles/.agents/skills/atlcli"
TAG="2026-03-31"
curl -fsSL https://atlcli.sh/sitemap-index.xml > "$SKILL_DIR/artifacts/sitemap-index-$TAG.xml"
curl -fsSL https://atlcli.sh/sitemap-0.xml > "$SKILL_DIR/artifacts/sitemap-0-$TAG.xml"
$SKILL_DIR/scripts/extract_doc_commands.py "$SKILL_DIR/artifacts" --tag "$TAG" > "$SKILL_DIR/artifacts/extract-run-$TAG.txt"
```

Extraction outputs:
- `artifacts/doc-urls-2026-03-31.txt`
- `artifacts/extracted-commands-2026-03-31.txt`
- `artifacts/extract-run-2026-03-31.txt`
- `artifacts/crawl-manifest-2026-03-31.tsv`
- `artifacts/sitemap-hashes-2026-03-31.tsv`
- `artifacts/extract-meta-2026-03-31.txt`

## Stored artifacts

- `artifacts/atlcli-version-2026-03-31.txt`
- `artifacts/atlcli-help-2026-03-31.txt`
- `artifacts/sitemap-index-2026-03-31.xml`
- `artifacts/sitemap-0-2026-03-31.xml`
- `artifacts/doc-urls-2026-03-31.txt`
- `artifacts/extracted-commands-2026-03-31.txt`
- `artifacts/extract-run-2026-03-31.txt`
- `artifacts/crawl-manifest-2026-03-31.tsv`
- `artifacts/sitemap-hashes-2026-03-31.tsv`
- `artifacts/extract-meta-2026-03-31.txt`

## Notes

- Command reference is snapshot-based and best-effort.
- Extraction is repeatable with the same script and inputs, but web content can change over time.
- Extract script is strict by default and fails on crawl errors (unless `--allow-partial` is set).
- Plugin/feature-flag command families vary by installation.
