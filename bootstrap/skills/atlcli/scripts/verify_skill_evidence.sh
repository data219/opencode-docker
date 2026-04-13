#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="${1:-/home/jan/.dotfiles/.agents/skills/atlcli}"
ART="$SKILL_DIR/artifacts"

sha256sum -c "$ART/baseline-pre-fix-skill-snippets-2026-03-31.sha256"
sha256sum -c "$ART/current-post-fix-skill-snippets-2026-03-31.sha256"

BASE="$ART/baseline-pre-fix-skill-snippets-2026-03-31.txt"
CUR="$ART/current-post-fix-skill-snippets-2026-03-31.txt"

if grep -q "add-inline" "$BASE"; then
  echo "FAIL: baseline unexpectedly contains add-inline"
  exit 1
fi
if grep -q "explicit user ACK" "$BASE"; then
  echo "FAIL: baseline unexpectedly contains ACK rule"
  exit 1
fi

grep -q "add-inline" "$CUR"
grep -q -- "--match-index" "$CUR"
grep -q "explicit user ACK" "$CUR"
grep -q "stop and ask for explicit risk acceptance" "$CUR"

echo "PASS: baseline/current evidence assertions succeeded"
