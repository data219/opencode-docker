#!/bin/bash
# docker-init.sh — Config seeding with version-based re-seeding
set -euo pipefail
trap 'echo "ERROR: docker-init.sh failed at line $LINENO" >&2' ERR

DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
OMO_DEFAULTS_DIR="${OMO_DEFAULTS_DIR:-/opt/omo-defaults}"
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"
USER_HOME="${USER_HOME:-/home/opencode}"
CONFIG_VERSION_FILE="$CONFIG_DIR/.opencode-docker-config-version"
IMAGE_VERSION_FILE="$DEFAULTS_DIR/.opencode-docker-config-version"

# Fix ownership of the persisted home tree BEFORE seeding.
# Docker creates bind mount targets as root when they don't exist on host.
if [ "$(id -u)" = "0" ]; then
  if [ -d "/home/opencode" ] && [ "$(stat -c %U /home/opencode 2>/dev/null)" = "root" ]; then
    chown -R opencode:opencode /home/opencode
  fi

  for dir in .config .config/opencode .config/opencode/skills .config/gh .config/glab .omo .omo/teams .local .local/share .local/state .local/state/opencode .local/share/opencode workspace; do
    dir_path="/home/opencode/$dir"
    if [ -d "$dir_path" ] && [ "$(stat -c %U "$dir_path" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir_path"
    fi
  done
  
  for dir in /home/opencode/.config /home/opencode/.cache /home/opencode/.local /home/opencode/.local/share /home/opencode/.local/state; do
    mkdir -p "$dir"
    if [ "$(stat -c %U "$dir" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir"
    fi
  done
fi

# --- Auto-generate SSH key if missing ---
SSH_DIR="${USER_HOME}/.ssh"
SSH_PRIVATE_KEY_PATH="${SSH_DIR}/id_ed25519"
SSH_PUBLIC_KEY_PATH="${SSH_PRIVATE_KEY_PATH}.pub"

mkdir -p "${SSH_DIR}"
if [ "$(id -u)" = "0" ]; then
  chown opencode:opencode "${SSH_DIR}"
fi
chmod 700 "${SSH_DIR}" 2>/dev/null || true

if [ ! -f "${SSH_PRIVATE_KEY_PATH}" ] && [ ! -f "${SSH_PUBLIC_KEY_PATH}" ]; then
  # Both keys missing: generate a new pair.
  if [ ! -w "${SSH_DIR}" ]; then
    echo "NOTE: SSH key missing and ${SSH_DIR} is not writable, skipping SSH key generation" >&2
  else
    echo "Generating SSH ed25519 key..."
    if ssh-keygen -t ed25519 -N "" -f "${SSH_PRIVATE_KEY_PATH}" >/dev/null 2>&1; then
      chmod 600 "${SSH_PRIVATE_KEY_PATH}" 2>/dev/null || true
      chmod 644 "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
      if [ "$(id -u)" = "0" ]; then
        chown opencode:opencode "${SSH_PRIVATE_KEY_PATH}" "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
      fi
      echo "SSH key generated. Public key:"
      cat "${SSH_PUBLIC_KEY_PATH}"
    else
      echo "WARNING: Failed to generate SSH key, continuing without it" >&2
    fi
  fi
elif [ -f "${SSH_PRIVATE_KEY_PATH}" ] && [ ! -f "${SSH_PUBLIC_KEY_PATH}" ]; then
  # Private key exists but public key is missing: derive it.
  echo "SSH public key missing, regenerating from private key..."
  if ssh-keygen -y -f "${SSH_PRIVATE_KEY_PATH}" > "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null; then
    chmod 644 "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
    if [ "$(id -u)" = "0" ]; then
      chown opencode:opencode "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
    fi
    echo "SSH public key regenerated. Public key:"
    cat "${SSH_PUBLIC_KEY_PATH}"
  else
    echo "WARNING: Failed to regenerate SSH public key" >&2
  fi
elif [ ! -f "${SSH_PRIVATE_KEY_PATH}" ] && [ -f "${SSH_PUBLIC_KEY_PATH}" ]; then
  # Orphaned public key without private key: remove and regenerate.
  echo "SSH private key missing but public key exists, regenerating key pair..."
  rm -f "${SSH_PUBLIC_KEY_PATH}"
  if ssh-keygen -t ed25519 -N "" -f "${SSH_PRIVATE_KEY_PATH}" >/dev/null 2>&1; then
    chmod 600 "${SSH_PRIVATE_KEY_PATH}" 2>/dev/null || true
    chmod 644 "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
    if [ "$(id -u)" = "0" ]; then
      chown opencode:opencode "${SSH_PRIVATE_KEY_PATH}" "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true
    fi
    echo "SSH key regenerated. Public key:"
    cat "${SSH_PUBLIC_KEY_PATH}"
  else
    echo "WARNING: Failed to regenerate SSH key" >&2
  fi
fi


mkdir -p "$CONFIG_DIR"

# Determine if we need to seed configs.
# We seed if:
#   1. Config dir is empty (first start with empty volume), OR
#   2. Image has a newer config version than what's in the volume
NEED_SEED=false
if [ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
  NEED_SEED=true
elif [ -f "$IMAGE_VERSION_FILE" ]; then
  IMAGE_VERSION=$(cat "$IMAGE_VERSION_FILE" 2>/dev/null || echo "0")
  VOLUME_VERSION=$(cat "$CONFIG_VERSION_FILE" 2>/dev/null || echo "0")
  if [ "$IMAGE_VERSION" -gt "$VOLUME_VERSION" ] 2>/dev/null; then
    echo "Config version upgraded: $VOLUME_VERSION → $IMAGE_VERSION. Re-seeding configs..."
    NEED_SEED=true
  fi
fi

if [ "$NEED_SEED" = "true" ] && [ -d "$DEFAULTS_DIR" ]; then
  # Re-seed managed configs (version-tracked), but preserve user customizations.
  # Files with ".managed" suffix are always overwritten from image defaults.
  # The ".managed" suffix is stripped when copying to the config dir.
  # Regular files are only copied if they don't exist yet.
  shopt -s dotglob nullglob
  for item in "$DEFAULTS_DIR"/*; do
    [ -e "$item" ] || continue
    base="$(basename "$item")"
    if [[ "$base" == *.managed ]]; then
      # Strip .managed suffix for the target filename
      target_name="${base%.managed}"
      target="$CONFIG_DIR/$target_name"
      cp -a -- "$item" "$target"
    else
      # Seed non-managed files only if they don't exist yet (first start)
      target="$CONFIG_DIR/$base"
      if [ ! -e "$target" ]; then
        cp -a -- "$item" "$target"
      fi
    fi
  done
  shopt -u dotglob nullglob

  # Update version marker in volume
  if [ -f "$IMAGE_VERSION_FILE" ]; then
    cp -a -- "$IMAGE_VERSION_FILE" "$CONFIG_VERSION_FILE"
  fi
fi

# Seed ~/.gitmessage only if it is missing.
if [ -f "$DEFAULTS_DIR/.gitmessage" ] && [ ! -f "$USER_HOME/.gitmessage" ]; then
  cp -a -- "$DEFAULTS_DIR/.gitmessage" "$USER_HOME/.gitmessage"
fi

# Configure git identity from env vars with safe defaults.
# Prefer OPENCODE_GIT_* inputs so reserved GIT_* override vars stay optional.
GIT_AUTHOR_NAME_OVERRIDE="${OPENCODE_GIT_AUTHOR_NAME:-${GIT_AUTHOR_NAME:-}}"
GIT_AUTHOR_EMAIL_OVERRIDE="${OPENCODE_GIT_AUTHOR_EMAIL:-${GIT_AUTHOR_EMAIL:-}}"
GIT_COMMITTER_NAME_OVERRIDE="${OPENCODE_GIT_COMMITTER_NAME:-${GIT_COMMITTER_NAME:-}}"
GIT_COMMITTER_EMAIL_OVERRIDE="${OPENCODE_GIT_COMMITTER_EMAIL:-${GIT_COMMITTER_EMAIL:-}}"
GIT_AUTHOR_NAME_EFFECTIVE="${GIT_AUTHOR_NAME_OVERRIDE:-Oh-MyOpenAgent}"
GIT_AUTHOR_EMAIL_EFFECTIVE="${GIT_AUTHOR_EMAIL_OVERRIDE:-noreply@ohmyopencode.ai}"
GIT_COMMITTER_NAME_EFFECTIVE="${GIT_COMMITTER_NAME_OVERRIDE:-Oh-MyOpenAgent}"
GIT_COMMITTER_EMAIL_EFFECTIVE="${GIT_COMMITTER_EMAIL_OVERRIDE:-noreply@ohmyopencode.ai}"
GIT_CONFIG_TARGET="${GIT_CONFIG_GLOBAL:-${GIT_CONFIG_TARGET:-$USER_HOME/.gitconfig}}"

git_set_or_seed() {
  local key="$1"
  local value="$2"
  local force="${3:-false}"
  local current
  current="$(git config --file "$GIT_CONFIG_TARGET" --get "$key" 2>/dev/null || true)"
  if [ "$force" = "true" ] || [ -z "$current" ]; then
    git config --file "$GIT_CONFIG_TARGET" "$key" "$value"
  fi
}

USER_NAME_FORCE="$([ -n "$GIT_AUTHOR_NAME_OVERRIDE" ] && echo true || echo false)"
USER_EMAIL_FORCE="$([ -n "$GIT_AUTHOR_EMAIL_OVERRIDE" ] && echo true || echo false)"
AUTHOR_NAME_FORCE="$([ -n "$GIT_AUTHOR_NAME_OVERRIDE" ] && echo true || echo false)"
AUTHOR_EMAIL_FORCE="$([ -n "$GIT_AUTHOR_EMAIL_OVERRIDE" ] && echo true || echo false)"
COMMITTER_NAME_FORCE="$([ -n "$GIT_COMMITTER_NAME_OVERRIDE" ] && echo true || echo false)"
COMMITTER_EMAIL_FORCE="$([ -n "$GIT_COMMITTER_EMAIL_OVERRIDE" ] && echo true || echo false)"

git_set_or_seed "user.name" "$GIT_AUTHOR_NAME_EFFECTIVE" "$USER_NAME_FORCE"
git_set_or_seed "user.email" "$GIT_AUTHOR_EMAIL_EFFECTIVE" "$USER_EMAIL_FORCE"

# Only write explicit author/committer overrides that were requested.
if [ "$AUTHOR_NAME_FORCE" = "true" ]; then
  git config --file "$GIT_CONFIG_TARGET" author.name "$GIT_AUTHOR_NAME_EFFECTIVE"
fi
if [ "$AUTHOR_EMAIL_FORCE" = "true" ]; then
  git config --file "$GIT_CONFIG_TARGET" author.email "$GIT_AUTHOR_EMAIL_EFFECTIVE"
fi
if [ "$COMMITTER_NAME_FORCE" = "true" ]; then
  git config --file "$GIT_CONFIG_TARGET" committer.name "$GIT_COMMITTER_NAME_EFFECTIVE"
fi
if [ "$COMMITTER_EMAIL_FORCE" = "true" ]; then
  git config --file "$GIT_CONFIG_TARGET" committer.email "$GIT_COMMITTER_EMAIL_EFFECTIVE"
fi

if [ -f "$USER_HOME/.gitmessage" ]; then
  git_set_or_seed "commit.template" "$USER_HOME/.gitmessage"
fi

CNTB_OAUTH2_CLIENT_ID_RAW="${CNTB_OAUTH2_CLIENT_ID:-}"
CNTB_OAUTH2_CLIENT_SECRET_RAW="${CNTB_OAUTH2_CLIENT_SECRET:-}"
CNTB_OAUTH2_USER_RAW="${CNTB_OAUTH2_USER:-}"
CNTB_OAUTH2_PASSWORD_RAW="${CNTB_OAUTH2_PASSWORD:-}"
CNTB_CREDENTIAL_COUNT=0
for value in "$CNTB_OAUTH2_CLIENT_ID_RAW" "$CNTB_OAUTH2_CLIENT_SECRET_RAW" "$CNTB_OAUTH2_USER_RAW" "$CNTB_OAUTH2_PASSWORD_RAW"; do
  if [ -n "$value" ]; then
    CNTB_CREDENTIAL_COUNT=$((CNTB_CREDENTIAL_COUNT + 1))
  fi
done

if [ "$CNTB_CREDENTIAL_COUNT" -gt 0 ] && [ "$CNTB_CREDENTIAL_COUNT" -lt 4 ]; then
  echo "ERROR: Incomplete cntb credentials. Set all of CNTB_OAUTH2_CLIENT_ID, CNTB_OAUTH2_CLIENT_SECRET, CNTB_OAUTH2_USER, and CNTB_OAUTH2_PASSWORD." >&2
  exit 1
fi

if [ "$CNTB_CREDENTIAL_COUNT" -eq 4 ]; then
  if ! command -v cntb >/dev/null 2>&1; then
    echo "ERROR: cntb credentials are set but cntb is not installed." >&2
    exit 1
  fi

  CNTB_CONFIG_FILE="$USER_HOME/.cntb.yaml"
  mkdir -p "$(dirname "$CNTB_CONFIG_FILE")"

  yaml_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"
  }

  CNTB_OLD_UMASK="$(umask)"
  umask 077
  {
    printf '%s\n' "debug: warn"
    printf '%s\n' "oauth2-tokenurl: https://auth.contabo.com/auth/realms/contabo/protocol/openid-connect/token"
    printf 'oauth2-clientid: %s\n' "$(yaml_quote "$CNTB_OAUTH2_CLIENT_ID_RAW")"
    printf 'oauth2-client-secret: %s\n' "$(yaml_quote "$CNTB_OAUTH2_CLIENT_SECRET_RAW")"
    printf 'oauth2-user: %s\n' "$(yaml_quote "$CNTB_OAUTH2_USER_RAW")"
    printf 'oauth2-password: %s\n' "$(yaml_quote "$CNTB_OAUTH2_PASSWORD_RAW")"
    printf '%s\n' "api: https://api.contabo.com"
  } > "$CNTB_CONFIG_FILE"
  umask "$CNTB_OLD_UMASK"
  chmod 600 "$CNTB_CONFIG_FILE"

  CNTB_OAUTH2_CLIENT_ID_RAW=
  CNTB_OAUTH2_CLIENT_SECRET_RAW=
  CNTB_OAUTH2_USER_RAW=
  CNTB_OAUTH2_PASSWORD_RAW=
  unset CNTB_OAUTH2_CLIENT_ID CNTB_OAUTH2_CLIENT_SECRET CNTB_OAUTH2_USER CNTB_OAUTH2_PASSWORD

  if [ "$(id -u)" = "0" ]; then
    chown -f opencode:opencode "$CNTB_CONFIG_FILE" 2>/dev/null || true
  fi

  CNTB_CONFIG_CMD=(
    env
    "HOME=$USER_HOME"
    cntb config set-credentials
  )

  if [ "$(id -u)" = "0" ]; then
    gosu opencode "${CNTB_CONFIG_CMD[@]}"
  else
    "${CNTB_CONFIG_CMD[@]}"
  fi
  unset CNTB_CONFIG_CMD CNTB_CONFIG_FILE CNTB_OLD_UMASK
fi

# Seed OmO agent config if not yet present (OmO install writes to temp dir during build).
# Only copy if oh-my-openagent.jsonc doesn't exist yet — don't overwrite user customizations.
if [ ! -f "$CONFIG_DIR/oh-my-openagent.jsonc" ]; then
  if [ -f "$DEFAULTS_DIR/oh-my-openagent-omo.jsonc" ]; then
    cp -a -- "$DEFAULTS_DIR/oh-my-openagent-omo.jsonc" "$CONFIG_DIR/oh-my-openagent.jsonc"
  elif [ -f "$DEFAULTS_DIR/oh-my-openagent-omo.json" ]; then
    cp -a -- "$DEFAULTS_DIR/oh-my-openagent-omo.json" "$CONFIG_DIR/oh-my-openagent.jsonc"
  fi
fi

# Ensure git files are writable by runtime user.
if [ "$(id -u)" = "0" ]; then
  chown -f opencode:opencode "$USER_HOME/.gitmessage" "$GIT_CONFIG_TARGET" 2>/dev/null || true
fi

# --- Sync bootstrap OmO teams ---
if [ -d "$OMO_DEFAULTS_DIR/teams" ]; then
  OMO_TEAMS_DIR="$USER_HOME/.omo/teams"
  OMO_TEAMS_OWNER=
  if [ -d "$OMO_TEAMS_DIR" ]; then
    OMO_TEAMS_OWNER="$(stat -c '%u:%g' "$OMO_TEAMS_DIR" 2>/dev/null || true)"
  fi
  mkdir -p "$OMO_TEAMS_DIR"

  # Merge bootstrap teams, but don't overwrite existing user modifications.
  for team_dir in "$OMO_DEFAULTS_DIR/teams"/*; do
    [ -d "${team_dir}" ] || continue
    target_dir="$OMO_TEAMS_DIR/$(basename "${team_dir}")"
    if [ ! -d "${target_dir}" ]; then
      cp -a "${team_dir}" "$target_dir"
    else
      cp -an "${team_dir}/." "$target_dir/"
    fi
  done

  # Preserve the bind mount owner instead of the image source owner.
  if [ "$(id -u)" = "0" ] && [ -d "$OMO_TEAMS_DIR" ]; then
    if [ -n "$OMO_TEAMS_OWNER" ]; then
      chown -R "$OMO_TEAMS_OWNER" "$OMO_TEAMS_DIR"
    else
      chown -R opencode:opencode "$USER_HOME/.omo" 2>/dev/null || true
    fi
  fi
fi

# --- Sync bootstrap skills ---
if [ -d "$DEFAULTS_DIR/skills" ]; then
  SKILLS_DIR="/home/opencode/.config/opencode/skills"
  mkdir -p "$SKILLS_DIR"
  if [ "${FORCE_SKILL_SYNC:-false}" = "true" ]; then
    # Full reset: remove all skills and re-copy from bootstrap
    rm -rf "${SKILLS_DIR:?}/"*
    cp -a "$DEFAULTS_DIR/skills/." "$SKILLS_DIR/"
  else
    # Merge: copy bootstrap skills, but don't overwrite existing user modifications
    for skill_dir in "$DEFAULTS_DIR/skills"/*; do
      [ -d "${skill_dir}" ] || continue
      target_dir="$SKILLS_DIR/$(basename "${skill_dir}")"
      if [ ! -d "${target_dir}" ]; then
        # New skill: copy entirely
        cp -a "${skill_dir}" "$target_dir"
      else
        # Existing skill: only add missing files, preserve user changes
        cp -an "${skill_dir}/." "$target_dir/"
      fi
    done
  fi

  # Preserve the bind mount owner instead of the image source owner.
  # This keeps the host user able to modify and delete synced skills even
  # when docker-init.sh runs as root inside the container.
  if [ "$(id -u)" = "0" ] && [ -d "$SKILLS_DIR" ]; then
    skills_owner="$(stat -c '%u:%g' "$SKILLS_DIR" 2>/dev/null || true)"
    if [ -n "$skills_owner" ]; then
      chown -R "$skills_owner" "$SKILLS_DIR"
    fi
  fi
fi
