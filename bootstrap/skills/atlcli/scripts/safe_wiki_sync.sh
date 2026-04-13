#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
safe_wiki_sync.sh - Safe AtlCLI Confluence sync flow

Usage:
  safe_wiki_sync.sh <docs-dir> [options]

Options:
  --profile <name>      AtlCLI profile to use
  --json                Enable JSON output where supported
  --diff-file <path>    Diff this file explicitly (repeatable)
  --no-push             Stop after pull/check/diff
  -h, --help            Show help

Flow:
  1) atlcli wiki docs pull <docs-dir>
  2) atlcli wiki docs check <docs-dir> --strict
  3) atlcli wiki docs diff <file> (explicit files or detected changed markdown files)
  4) atlcli wiki docs push <docs-dir> --validate
EOF
}

log() {
  printf '[safe_wiki_sync] %s\n' "$*"
}

run_cmd() {
  log "run: $*"
  "$@"
}

detect_git_changed_markdown() {
  local dir="$1"
  local repo_root abs_dir rel_dir

  if ! repo_root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"; then
    return 0
  fi

  abs_dir="$(cd "$dir" && pwd -P)"
  if [[ "$abs_dir" == "$repo_root" ]]; then
    rel_dir="."
  else
    rel_dir="${abs_dir#"$repo_root"/}"
  fi

  {
    git -C "$repo_root" diff --name-only -- "$rel_dir"
    git -C "$repo_root" diff --cached --name-only -- "$rel_dir"
    git -C "$repo_root" ls-files --others --exclude-standard -- "$rel_dir"
  } | sed '/^$/d' | sort -u | while IFS= read -r rel_path; do
    [[ -z "$rel_path" ]] && continue
    [[ "$rel_path" != *.md ]] && continue
    printf '%s/%s\n' "$repo_root" "$rel_path"
  done
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

profile=""
json=false
no_push=false
docs_dir=""
declare -a diff_files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -lt 2 ]] && { log "missing value for --profile"; exit 2; }
      profile="$2"
      shift 2
      ;;
    --json)
      json=true
      shift
      ;;
    --diff-file)
      [[ $# -lt 2 ]] && { log "missing value for --diff-file"; exit 2; }
      diff_files+=("$2")
      shift 2
      ;;
    --no-push)
      no_push=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log "unknown option: $1"
      usage
      exit 2
      ;;
    *)
      if [[ -n "$docs_dir" ]]; then
        log "unexpected extra argument: $1"
        usage
        exit 2
      fi
      docs_dir="$1"
      shift
      ;;
  esac
done

if [[ -z "$docs_dir" ]]; then
  log "missing <docs-dir>"
  usage
  exit 2
fi

if [[ ! -d "$docs_dir" ]]; then
  log "docs directory not found: $docs_dir"
  exit 2
fi

if ! command -v atlcli >/dev/null 2>&1; then
  log "atlcli not found in PATH"
  exit 127
fi

declare -a atlcli_base=("atlcli")
if [[ -n "$profile" ]]; then
  atlcli_base+=("--profile" "$profile")
fi
if [[ "$json" == "true" ]]; then
  atlcli_base+=("--json")
fi

log "starting safe wiki docs sync flow"
run_cmd "${atlcli_base[@]}" wiki docs pull "$docs_dir"
run_cmd "${atlcli_base[@]}" wiki docs check "$docs_dir" --strict

if [[ ${#diff_files[@]} -eq 0 ]]; then
  while IFS= read -r discovered; do
    diff_files+=("$discovered")
  done < <(detect_git_changed_markdown "$docs_dir")
fi

if [[ ${#diff_files[@]} -eq 0 ]]; then
  log "no markdown diff targets detected; running status for visibility"
  run_cmd "${atlcli_base[@]}" wiki docs status "$docs_dir"
else
  for file in "${diff_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log "skip diff target (not a file): $file"
      continue
    fi
    run_cmd "${atlcli_base[@]}" wiki docs diff "$file"
  done
fi

if [[ "$no_push" == "true" ]]; then
  log "no-push enabled; stopping before push"
  exit 0
fi

run_cmd "${atlcli_base[@]}" wiki docs push "$docs_dir" --validate
log "sync flow completed"
