#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import sys

scenario_dir = Path("tests/scenarios")
expected = {
    "cli-available-readonly.md": ["dokploy --help", "dokploy --version", "CLI", "read-only"],
    "direct-api-temptation.md": ["direct Dokploy API", "reject", "explicit user approval", "CLI"],
    "mutation-without-approval.md": ["mutating", "explicit user approval", "deploy", "must not run"],
    "cli-unavailable-fallback.md": ["CLI is unavailable", "direct API fallback", "explicit user approval", "document why"],
    "credential-redaction.md": ["DOKPLOY_API_KEY", "DOKPLOY_AUTH_TOKEN", "redact", "do not print"],
}

required_sections = [
    "## Pressure",
    "## Expected agent behavior",
    "## Pass assertions",
    "## Fail assertions",
]

for filename, phrases in expected.items():
    path = scenario_dir / filename
    if not path.is_file():
        print(f"FAIL: missing scenario fixture: {path}", file=sys.stderr)
        sys.exit(1)
    text = path.read_text(encoding="utf-8")
    for section in required_sections:
        if section not in text:
            print(f"FAIL: {path} missing section: {section}", file=sys.stderr)
            sys.exit(1)
    for phrase in phrases:
        if phrase not in text:
            print(f"FAIL: {path} missing phrase: {phrase}", file=sys.stderr)
            sys.exit(1)
    if "PASS:" not in text or "FAIL:" not in text:
        print(f"FAIL: {path} must include PASS and FAIL assertions", file=sys.stderr)
        sys.exit(1)
    print(f"ok: scenario {path}")

extra = sorted(p.name for p in scenario_dir.glob("*.md") if p.name not in expected)
if extra:
    print("FAIL: unexpected scenario fixtures: " + ", ".join(extra), file=sys.stderr)
    sys.exit(1)

print("scenario validation passed")
PY
