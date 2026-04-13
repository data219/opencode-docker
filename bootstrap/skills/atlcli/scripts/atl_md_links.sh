#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
atl_md_links.sh - Render Atlassian entities as Markdown links from atlcli JSON

Usage:
  atlcli ... --json | atl_md_links.sh [--site <url>]

Options:
  --site <url>   Base Atlassian site URL (fallback for Jira issue links)
                 Defaults to ATLCLI_SITE if set.
  -h, --help     Show help.

Output:
  - [label](url)         for resolved entities
  - UNRESOLVED<TAB>label when no canonical URL could be derived
EOF
}

site="${ATLCLI_SITE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site)
      [[ $# -lt 2 ]] && { echo "[atl_md_links] missing value for --site" >&2; exit 2; }
      site="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[atl_md_links] unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "[atl_md_links] jq not found in PATH" >&2
  exit 127
fi

jq -r --arg site "$site" '
  def rows:
    if type == "array" then .
    elif .issues? then .issues
    elif .projects? then .projects
    elif .boards? then .boards
    elif .sprints? then .sprints
    elif .spaces? then .spaces
    elif .pages? then .pages
    elif .results? then .results
    elif .values? then .values
    elif .items? then .items
    else [.] end;

  def link_from_links:
    if (._links.base? and ._links.webui?) then
      (._links.base + ._links.webui)
    elif (._links.webui? and (._links.webui | type == "string") and (._links.webui | startswith("http"))) then
      ._links.webui
    elif (._links.webui? and (._links.webui | type == "string") and (._links.webui | startswith("/")) and ($site != "")) then
      ($site + ._links.webui)
    else
      null
    end;

  def pick_url:
    .url // .webUrl // .htmlUrl // .browseUrl //
    (link_from_links) //
    (if (.key? and ($site != "")) then ($site + "/browse/" + (.key | tostring)) else null end);

  rows[] as $e
  | ($e | pick_url) as $u
  | ($e.key // $e.name // $e.title // $e.id // "unknown") as $label
  | if ($u // "") == "" then
      "UNRESOLVED\t\($label|tostring)"
    else
      "[\($label|tostring)](\($u))"
    end
'
