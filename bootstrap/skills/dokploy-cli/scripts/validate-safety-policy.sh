#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re
import sys

checks = {
    "SKILL.md": [
        "Dokploy CLI",
        "direct Dokploy API",
        "explicit user approval",
        "mutating",
        "do not print tokens",
        "DOKPLOY_API_KEY",
        "DOKPLOY_AUTH_TOKEN",
        "Do not inspect local Dokploy config or auth files",
    ],
    "README.md": [
        "Prefer `dokploy` CLI commands",
        "Do not print tokens",
        "explicit approval",
        "direct Dokploy API fallback",
        "public CI",
        "do not query live server data",
    ],
    "COMMAND-REFERENCE.md": [
        "SKILL.md is the normative source",
        "dokploy --help",
        "dokploy --version",
        "dokploy <group> --help",
        "Auth precedence",
        "DOKPLOY_API_KEY or DOKPLOY_AUTH_TOKEN",
        "Generated command pattern",
        "`--json`",
        "no global dry-run",
        "High-risk verbs to gate",
        "explicit user approval",
        "Do not bypass the CLI with direct API calls",
    ],
}

for filename, phrases in checks.items():
    text = Path(filename).read_text(encoding="utf-8")
    for phrase in phrases:
        if phrase not in text:
            print(f"FAIL: {filename} missing required phrase: {phrase}", file=sys.stderr)
            sys.exit(1)
    print(f"ok: required safety phrases in {filename}")

combined = "\n".join(Path(name).read_text(encoding="utf-8") for name in checks)

forbidden_patterns = [
    (r"dokp_[A-Za-z0-9]+", "Dokploy token-looking value"),
    (r"ghp_[A-Za-z0-9]+", "GitHub token-looking value"),
    (r"sk-[A-Za-z0-9]{8,}", "API token-looking value"),
    (r"(?i)DOKPLOY_(?:API_KEY|AUTH_TOKEN|URL)\s*=", "Dokploy environment assignment"),
    (r"(?i)Authorization\s*:\s*Bearer", "bearer authorization example"),
    (r"(?i)curl\s+[^\n]*(?:dokploy|DOKPLOY|/api/)", "direct Dokploy API curl example"),
    (r"(?i)(?:fetch|axios)\s*\([^\n]*(?:dokploy|DOKPLOY|/api/)", "direct Dokploy API client example"),
]

for pattern, label in forbidden_patterns:
    if re.search(pattern, combined):
        print(f"FAIL: forbidden pattern found: {label}", file=sys.stderr)
        sys.exit(1)

print("safety policy validation passed")
PY
