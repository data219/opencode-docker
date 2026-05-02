#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.env}"
EXAMPLE_FILE="${2:-.env.example}"

RENAMES=(
  "ZHIPU_API_KEY:OCD_ZHIPU_API_KEY"
  "GEMINI_API_KEY:OCD_GEMINI_API_KEY"
)

if [ ! -f "$EXAMPLE_FILE" ]; then
  echo "ERROR: example env file not found: $EXAMPLE_FILE" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  install -m 0600 /dev/null "$ENV_FILE"
fi

escape_regex() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g'
}

env_var_exists() {
  local file="$1"
  local name="$2"
  local escaped_name
  escaped_name="$(escape_regex "$name")"

  grep -Eq "^[[:space:]]*#?[[:space:]]*${escaped_name}[[:space:]]*=" "$file"
}

active_env_var_exists() {
  local file="$1"
  local name="$2"
  local escaped_name
  escaped_name="$(escape_regex "$name")"

  grep -Eq "^[[:space:]]*${escaped_name}[[:space:]]*=" "$file"
}

rename_env_var() {
  local file="$1"
  local old_name="$2"
  local new_name="$3"
  local old_escaped
  local tmp

  old_escaped="$(escape_regex "$old_name")"
  tmp="$(mktemp "${file}.XXXXXX")"

  if active_env_var_exists "$file" "$old_name" && ! active_env_var_exists "$file" "$new_name"; then
    sed -E "s/^([[:space:]]*)${old_escaped}([[:space:]]*=)/\\1${new_name}\\2/" "$file" > "$tmp"
  elif active_env_var_exists "$file" "$old_name" && active_env_var_exists "$file" "$new_name"; then
    sed -E "s/^([[:space:]]*)${old_escaped}([[:space:]]*=)/\\1# ${old_name}\\2/" "$file" > "$tmp"
  else
    cp "$file" "$tmp"
  fi

  mv "$tmp" "$file"
}

append_missing_from_example() {
  local env_file="$1"
  local example_file="$2"
  local appended=false
  local line
  local name

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*#?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*= ]]; then
      name="${BASH_REMATCH[1]}"
      if ! env_var_exists "$env_file" "$name"; then
        if [ "$appended" = false ]; then
          {
            printf '\n'
            printf '# --- Added by scripts/migrate-env.sh from %s ---\n' "$example_file"
          } >> "$env_file"
          appended=true
        fi
        printf '%s\n' "$line" >> "$env_file"
      fi
    fi
  done < "$example_file"
}

for rename in "${RENAMES[@]}"; do
  old_name="${rename%%:*}"
  new_name="${rename#*:}"
  rename_env_var "$ENV_FILE" "$old_name" "$new_name"
done

append_missing_from_example "$ENV_FILE" "$EXAMPLE_FILE"
