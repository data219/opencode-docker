#!/bin/bash
# docker-init.sh — Config seeding with version-based re-seeding
set -euo pipefail
trap 'echo "ERROR: docker-init.sh failed at line $LINENO" >&2' ERR

DEFAULTS_DIR="${DEFAULTS_DIR:-/opt/opencode-defaults}"
OMO_DEFAULTS_DIR="${OMO_DEFAULTS_DIR:-/opt/omo-defaults}"
CONFIG_DIR="${CONFIG_DIR:-/home/opencode/.config/opencode}"
USER_HOME="${USER_HOME:-/home/opencode}"
VARIANTS_DIR="${DEFAULTS_DIR}/variants"
CONFIG_VARIANT="${OPENCODE_CONFIG_VARIANT:-openai-chatgpt}"
CONFIG_VARIANT_DIR=""
CONFIG_VARIANT_FILE="$CONFIG_DIR/.opencode-docker-config-variant"
CONFIG_VERSION_FILE="$CONFIG_DIR/.opencode-docker-config-version"
IMAGE_VERSION_FILE="$DEFAULTS_DIR/.opencode-docker-config-version"

if [ -z "$CONFIG_VARIANT" ]; then
  CONFIG_VARIANT="openai-chatgpt"
fi

list_config_variants() {
  local variant_dir
  if [ ! -d "$VARIANTS_DIR" ]; then
    return 1
  fi
  for variant_dir in "$VARIANTS_DIR"/*; do
    [ -d "$variant_dir" ] || continue
    printf '  %s\n' "$(basename "$variant_dir")"
  done
}

resolve_config_variant() {
  local requested_variant="$CONFIG_VARIANT"
  local variant_dir

  if [ ! -d "$VARIANTS_DIR" ]; then
    CONFIG_VARIANT_DIR="$DEFAULTS_DIR"
    return
  fi

  for variant_dir in "$VARIANTS_DIR"/*; do
    [ -d "$variant_dir" ] || continue
    if [ "$requested_variant" = "$(basename "$variant_dir")" ]; then
      CONFIG_VARIANT_DIR="$variant_dir"
      return
    fi
  done

  echo "ERROR: unknown config variant: $requested_variant" >&2
  echo "Available variants:" >&2
  list_config_variants >&2
  exit 1
}

resolve_config_variant

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
  
  for dir in /home/opencode/.config /home/opencode/.cache /home/opencode/.local /home/opencode/.local/share /home/opencode/.local/state "$USER_HOME/.omo"; do
    mkdir -p "$dir"
    if [ "$(stat -c %U "$dir" 2>/dev/null)" = "root" ]; then
      chown -R opencode:opencode "$dir"
    fi
  done
fi

# --- Seed home directory from image defaults (non-destructive) ---
# Copies missing files/dirs from the image's home tree using cp -an.
# -a preserves permissions/ownership/timestamps; -n skips existing files.
# .config/opencode is explicitly skipped: version-tracked managed seeding
# below owns that directory and its files.
# Idempotent: on subsequent starts, -n makes cp a no-op.
DEFAULT_HOME_DIR="${DEFAULT_HOME_DIR:-/opt/opencode-default-home}"
if [ "$(id -u)" = "0" ] && [ -d "${DEFAULT_HOME_DIR}" ]; then
  echo "Seeding home directory from image defaults..."
  for _item in "${DEFAULT_HOME_DIR}/"* "${DEFAULT_HOME_DIR}/".[!.]*; do
    [ -e "$_item" ] || continue
    case "$(basename "$_item")" in
      .config)
        # Copy .config contents except opencode/ (managed seeding owns it)
        mkdir -p "${USER_HOME}/.config"
        for _sub in "$_item"/* "$_item"/.[!.]*; do
          [ -e "$_sub" ] || continue
          [ "$(basename "$_sub")" = "opencode" ] && continue
          cp -an "$_sub" "${USER_HOME}/.config/" 2>/dev/null || true
        done
        ;;
      *)
        cp -an "$_item" "${USER_HOME}/" 2>/dev/null || true
        ;;
    esac
  done
  echo "Home directory seed complete."
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

if [ -f "$CONFIG_VARIANT_FILE" ] && [ "$(cat "$CONFIG_VARIANT_FILE" 2>/dev/null || true)" != "$CONFIG_VARIANT" ]; then
  echo "Config variant changed: $(cat "$CONFIG_VARIANT_FILE" 2>/dev/null || echo "<none>") → $CONFIG_VARIANT. Re-seeding selected files..."
  NEED_SEED=true
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
    if [ "$base" = "variants" ]; then
      continue
    fi
    if [[ "$base" == *.managed ]]; then
      # Strip .managed suffix for the target filename
      target_name="${base%.managed}"
      target="$CONFIG_DIR/$target_name"
      source_file="$item"
      variant_source_file="$CONFIG_VARIANT_DIR/$target_name"
      if [ -f "$variant_source_file" ]; then
        source_file="$variant_source_file"
      fi
      cp -a -- "$source_file" "$target"
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
  echo "$CONFIG_VARIANT" > "$CONFIG_VARIANT_FILE"
fi

# Seed ~/.gitmessage only if it is missing.
if [ -f "$DEFAULTS_DIR/.gitmessage" ] && [ ! -f "$USER_HOME/.gitmessage" ]; then
  cp -a -- "$DEFAULTS_DIR/.gitmessage" "$USER_HOME/.gitmessage"
fi

is_github_https_repo() {
  case "$1" in
    https://github.com/*|https://www.github.com/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

clone_dotfiles_repo() {
  local repo_url="$1"
  local target_dir="$2"
  local askpass_dir="$3"
  local github_token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

  if is_github_https_repo "$repo_url" && [ -n "$github_token" ]; then
    local askpass_script
    local clone_status=0
    askpass_script="$(mktemp "$askpass_dir/git-askpass.XXXXXX")"
    cat > "$askpass_script" <<'EOF'
#!/bin/sh
case "$1" in
  *Username*)
    printf '%s\n' 'x-access-token'
    ;;
  *)
    printf '%s\n' "${OPENCODE_DOTFILES_GITHUB_TOKEN:-}"
    ;;
esac
EOF
    chmod 700 "$askpass_script"

    OPENCODE_DOTFILES_GITHUB_TOKEN="$github_token" \
      GIT_ASKPASS="$askpass_script" \
      GIT_TERMINAL_PROMPT=0 \
      git -c credential.helper= clone --depth 1 "$repo_url" "$target_dir" || clone_status=$?
    rm -f "$askpass_script"
    return "$clone_status"
  fi

  GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$repo_url" "$target_dir"
}

install_dotfiles_repo() {
  local repo_url="${OPENCODE_DOTFILES_REPO:-}"
  [ -n "$repo_url" ] || return 0

  local dotfiles_base="$USER_HOME/.opencode-dotfiles"
  local dotfiles_repo_dir="$dotfiles_base/repo"
  local dotfiles_repo_marker="$dotfiles_base/repo-id"
  local legacy_dotfiles_repo_marker="$dotfiles_base/repo-url"
  local dotfiles_tmp_dir="$dotfiles_base/repo.tmp"
  local repo_identifier
  local current_repo_identifier=""

  repo_identifier="$(printf '%s' "$repo_url" | sha256sum | awk '{print $1}')"

  if [ -f "$dotfiles_repo_marker" ]; then
    current_repo_identifier="$(cat "$dotfiles_repo_marker" 2>/dev/null || true)"
  fi
  if [ "$current_repo_identifier" = "$repo_identifier" ] && [ -d "$dotfiles_repo_dir" ]; then
    echo "Dotfiles repo already installed; skipping."
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: OPENCODE_DOTFILES_REPO is set but git is not installed." >&2
    exit 1
  fi

  echo "Installing dotfiles repo..."
  mkdir -p "$dotfiles_base"
  rm -f "$legacy_dotfiles_repo_marker"
  rm -rf "$dotfiles_tmp_dir"
  if ! clone_dotfiles_repo "$repo_url" "$dotfiles_tmp_dir" "$dotfiles_base"; then
    echo "ERROR: Failed to clone OPENCODE_DOTFILES_REPO. For private GitHub HTTPS repositories, set GH_TOKEN or GITHUB_TOKEN with repository read access. SSH URLs require a key with repository access." >&2
    exit 1
  fi
  rm -rf "$dotfiles_repo_dir"
  mv "$dotfiles_tmp_dir" "$dotfiles_repo_dir"

  if [ "$(id -u)" = "0" ]; then
    if [ "$(stat -c %U "$USER_HOME" 2>/dev/null)" = "root" ]; then
      chown opencode:opencode "$USER_HOME" 2>/dev/null || true
    fi
    chown -R opencode:opencode "$dotfiles_base" 2>/dev/null || true
  fi

  local installer=""
  local candidate
  for candidate in \
    install.sh \
    install \
    bootstrap.sh \
    bootstrap \
    script/bootstrap \
    setup.sh \
    setup \
    script/setup; do
    if [ -f "$dotfiles_repo_dir/$candidate" ]; then
      installer="$candidate"
      break
    fi
  done

  if [ -n "$installer" ]; then
    chmod +x "$dotfiles_repo_dir/$installer" 2>/dev/null || true
    if [ "$(id -u)" = "0" ] && command -v gosu >/dev/null 2>&1; then
      gosu opencode env HOME="$USER_HOME" USER_HOME="$USER_HOME" bash -lc "cd \"\$1\" && exec \"./\$2\"" bash "$dotfiles_repo_dir" "$installer"
    elif [ "$(id -u)" = "0" ] && command -v runuser >/dev/null 2>&1; then
      runuser -u opencode -- env HOME="$USER_HOME" USER_HOME="$USER_HOME" bash -lc "cd \"\$1\" && exec \"./\$2\"" bash "$dotfiles_repo_dir" "$installer"
    else
      (cd "$dotfiles_repo_dir" && env HOME="$USER_HOME" USER_HOME="$USER_HOME" "./$installer")
    fi
  else
    mkdir -p "$USER_HOME/.config"
    shopt -s dotglob nullglob
    for candidate in "$dotfiles_repo_dir"/.[!.]* "$dotfiles_repo_dir"/..?*; do
      [ -e "$candidate" ] || continue
      local candidate_base
      candidate_base="$(basename "$candidate")"
      [ "$candidate_base" = ".git" ] && continue
      local target
      target="$USER_HOME/$candidate_base"
      if [ "$candidate_base" = ".config" ] && [ -d "$candidate" ] && [ -d "$target" ]; then
        local config_entry
        for config_entry in "$candidate"/* "$candidate"/.[!.]* "$candidate"/..?*; do
          [ -e "$config_entry" ] || continue
          local config_target
          config_target="$target/$(basename "$config_entry")"
          if [ ! -e "$config_target" ] && [ ! -L "$config_target" ]; then
            ln -s "$config_entry" "$config_target"
          fi
        done
      elif [ ! -e "$target" ] && [ ! -L "$target" ]; then
        ln -s "$candidate" "$target"
      fi
    done
    shopt -u dotglob nullglob
  fi

  printf '%s\n' "$repo_identifier" > "$dotfiles_repo_marker"
  if [ "$(id -u)" = "0" ]; then
    chown -R opencode:opencode "$dotfiles_base" 2>/dev/null || true
    chown -h opencode:opencode "$USER_HOME"/.[!.]* "$USER_HOME"/..?* 2>/dev/null || true
  fi
  echo "Dotfiles install complete."
}

install_dotfiles_repo

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

# Seed OmO agent config if not yet present (OmO now installs normally to /home/opencode).
# Only copy if oh-my-openagent.jsonc doesn't exist yet — don't overwrite user customizations.
if [ ! -f "$CONFIG_DIR/oh-my-openagent.jsonc" ]; then
  if [ -f "$DEFAULTS_DIR/omo-generated-oh-my-openagent.jsonc" ]; then
    cp -a -- "$DEFAULTS_DIR/omo-generated-oh-my-openagent.jsonc" "$CONFIG_DIR/oh-my-openagent.jsonc"
  elif [ -f "$DEFAULTS_DIR/omo-generated-oh-my-openagent.json" ]; then
    cp -a -- "$DEFAULTS_DIR/omo-generated-oh-my-openagent.json" "$CONFIG_DIR/oh-my-openagent.jsonc"
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
      omo_fallback_owner="$(stat -c '%u:%g' "$USER_HOME/.omo" 2>/dev/null || stat -c '%u:%g' "$USER_HOME" 2>/dev/null || true)"
      if [ -n "$omo_fallback_owner" ]; then
        chown -R "$omo_fallback_owner" "$OMO_TEAMS_DIR" 2>/dev/null || true
      fi
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
