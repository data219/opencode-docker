---
name: context7
description: Use when searching library documentation, retrieving context from repos, or using LLM-powered ranking for docs queries
always: true
---

# Context7 Query CLI

Intelligent documentation search with LLM-powered ranking for any library.

## When to Use

**Triggers:** Searching library docs, retrieving context from repos, LLM-reranked snippets needed, programmatic access to docs.

**Rule:** For library/framework/API/package documentation, use this skill first. Do not read docs directly from the web unless Context7 cannot answer or the user explicitly asks for web sources.

**NOT for:** General web search unrelated to library/framework/API/package docs.

## Quick Reference

**Search (with ranking):**
```bash
node --import tsx query.ts search <library_name> <query>
node --import tsx query.ts s symfony voter
```

**Get context (specific repo):**
```bash
node --import tsx query.ts context <owner/repo> <query>
node --import tsx query.ts c symfony/symfony-docs voter
```

**Resolve + fetch in one step:**
```bash
node --import tsx query.ts ask symfony "how do I build a voter?"
node --import tsx query.ts a nextjs "middleware redirect auth" --json
```

**JSON output (for scripting):**
```bash
node --import tsx query.ts search symfony voter --json
node --import tsx query.ts c symfony/symfony-docs voter -j
```

**Enable caching (24h TTL):**
```bash
node --import tsx query.ts search symfony voter --cache
node --import tsx query.ts c symfony/symfony-docs voter --cache
```

**Combined options:**
```bash
node --import tsx query.ts s symfony voter --json --cache
node --import tsx query.ts a symfony "security voter" --json --max-chars 5000 --max-sections 6
```

## New Features (v1.1.0)

### JSON Output Mode
Use `--json` or `-j` flag for structured output suitable for parsing in scripts or automation:
- Search returns: `{"query": "...", "count": N, "results": [...]}`
- Context returns: `{"libraryId": "...", "query": "...", "context": "...", "cached": boolean}`
- All errors return JSON when flag is set

### Local Caching
Use `--cache` flag to enable local caching (default: disabled):
- Cache stored outside the repository in `${XDG_CACHE_HOME:-$HOME/.cache}/codex-context7`
- 24-hour TTL for cached results
- Automatic cache invalidation after expiration
- Shows "(cached)" indicator in console output
- Significantly faster for repeated queries

### Token Optimization
The skill now optimizes context locally before it reaches the model:
- `--max-chars <n>` hard-limits payload size
- `--max-sections <n>` keeps only the most relevant sections plus nearby code blocks
- `--raw` disables local compression when you want the full response
- `--stats` reports before/after character and token estimates
- JSON mode stays machine-readable on cache hits
- `ask` fails on ambiguous library resolution instead of silently taking the first hit

### Enhanced Error Handling
- Clear error messages for API failures (401, 404, etc.)
- Network error handling with URL display
- Consistent error format for both console and JSON modes
- Graceful fallback for cache failures

## Setup

Copy `.env.example` to `.env` if you want a local fallback, or provide `CONTEXT7_API_KEY` through the shell environment, then run `npm install`.

## Common Mistakes

- Missing original query → Poor ranking
- Search for known library → Slower than context endpoint
- Wrong version: `/vercel/next.js` vs `/vercel/next.js/v12` → Incorrect docs
- Wrong response type: `type=json` for LLM → Extra parsing
- Not using cache for repeated queries → Slower performance
- Parsing JSON without `--json` flag → Unstructured text output
- Forgetting `--max-chars` / `--max-sections` in token-sensitive flows → Larger-than-needed model context

## API

```
GET https://context7.com/api/v2/libs/search?libraryName=<name>&query=<query>
GET https://context7.com/api/v2/context?libraryId=<owner/repo>&query=<query>&type=txt|json
```

**Navigation:** https://context7.com/docs/llms.txt

## Cache Management

Clear cache manually:
```bash
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/codex-context7"
```

Cache location: `${XDG_CACHE_HOME:-$HOME/.cache}/codex-context7` with format `context7_<type>_<hash>.json`

## Benchmarking

Compare local skill vs real MCP path:
```bash
npm run benchmark -- --file benchmark.queries.example.json
```

The benchmark:
- runs the local skill with `--json --no-cache`
- starts a real Context7 MCP server via Docker
- measures wall time, chars, bytes, and estimated tokens
- prints both a readable summary and raw JSON
- requires pinned `libraryId` values so both paths hit the same docs corpus
- reports token estimates as a character-based proxy, not a model-accurate tokenizer result

## Routing Eval Fixtures

Prompt-eval fixtures for the docs-first policy live in `routing-evals.json`.
Use them to verify that docs prompts choose Context7 before any web lookup.
