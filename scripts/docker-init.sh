#!/bin/bash
# docker-init.sh — Config seeding with version-based re-seeding
set -euo pipefail
trap 'echo "ERROR: docker-init.sh failed at line $LINENO" >&2' ERR

DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
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

  for dir in .config .config/opencode .config/opencode/skills .config/gh .config/glab .local .local/share .local/state .local/state/opencode .local/share/opencode workspace; do
    dir_path="/home/opencode/$dir"
    if [ -d "$dir_path" ] && [ "$(stat -c %U "$dir_path" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir_path"
    fi
  done
  
  for dir in /home/opencode/.config /home/opencode/.cache /home/opencode/.local /home/opencode/.local/share /home/opencode/.local/state; do
    mkdir -p "$dir"
    chown -R opencode:opencode "$dir"
  done
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
GIT_AUTHOR_NAME_EFFECTIVE="${GIT_AUTHOR_NAME:-Oh-MyOpenAgent}"
GIT_AUTHOR_EMAIL_EFFECTIVE="${GIT_AUTHOR_EMAIL:-noreply@ohmyopencode.ai}"
GIT_COMMITTER_NAME_EFFECTIVE="${GIT_COMMITTER_NAME:-Oh-MyOpenAgent}"
GIT_COMMITTER_EMAIL_EFFECTIVE="${GIT_COMMITTER_EMAIL:-noreply@ohmyopencode.ai}"
GIT_CONFIG_TARGET="${GIT_CONFIG_GLOBAL:-${GIT_CONFIG_TARGET:-$USER_HOME/.gitconfig}}"

git config --file "$GIT_CONFIG_TARGET" user.name "$GIT_AUTHOR_NAME_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" user.email "$GIT_AUTHOR_EMAIL_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" author.name "$GIT_AUTHOR_NAME_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" author.email "$GIT_AUTHOR_EMAIL_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" committer.name "$GIT_COMMITTER_NAME_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" committer.email "$GIT_COMMITTER_EMAIL_EFFECTIVE"
git config --file "$GIT_CONFIG_TARGET" commit.template "$USER_HOME/.gitmessage"

# Seed OmO agent config if not yet present (OmO install writes to temp dir during build).
# Only copy if oh-my-openagent.jsonc doesn't exist yet — don't overwrite user customizations.
if [ ! -f "$CONFIG_DIR/oh-my-openagent.jsonc" ] && [ -f "$DEFAULTS_DIR/oh-my-openagent-omo.json" ]; then
  cp -a -- "$DEFAULTS_DIR/oh-my-openagent-omo.json" "$CONFIG_DIR/oh-my-openagent.jsonc"
fi

# Ensure git files are writable by runtime user.
if [ "$(id -u)" = "0" ]; then
  chown -f opencode:opencode "$USER_HOME/.gitmessage" "$GIT_CONFIG_TARGET" 2>/dev/null || true
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
