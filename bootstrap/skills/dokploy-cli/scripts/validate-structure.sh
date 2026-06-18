#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
  printf 'ok: file %s\n' "$1"
}

require_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
  printf 'ok: directory %s\n' "$1"
}

require_executable() {
  [ -x "$1" ] || fail "not executable: $1"
  printf 'ok: executable %s\n' "$1"
}

require_file README.md
require_file SKILL.md
require_file COMMAND-REFERENCE.md
require_file agents/openai.yaml
require_file LICENSE

require_dir scripts
require_dir tests/scenarios

require_executable scripts/validate-structure.sh
require_executable scripts/validate-safety-policy.sh
require_executable scripts/validate-readonly-cli.sh
require_executable scripts/validate-scenarios.sh

for scenario in \
  tests/scenarios/cli-available-readonly.md \
  tests/scenarios/direct-api-temptation.md \
  tests/scenarios/mutation-without-approval.md \
  tests/scenarios/cli-unavailable-fallback.md \
  tests/scenarios/credential-redaction.md
do
  require_file "$scenario"
done

printf 'structure validation passed\n'
