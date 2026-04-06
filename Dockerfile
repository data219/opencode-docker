# opencode-docker — OpenCode + Oh-My-OpenAgent with GLM-5
# Single-stage build with BuildKit cache mounts
# Requires: DOCKER_BUILDKIT=1

FROM debian:bookworm-slim

# --- System packages (with BuildKit cache for apt) ---
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
       curl git vim nano jq findutils openssh-client \
       build-essential make pkg-config autoconf bison re2c \
       unzip xz-utils ca-certificates gnupg \
       libssl-dev libcurl4-openssl-dev libxml2-dev \
       libpq-dev libsqlite3-dev libffi-dev libzip-dev \
       libicu-dev libonig-dev sqlite3 zip \
    && rm -rf /var/lib/apt/lists/*

# --- Create non-root user ---
RUN groupadd -g 1000 opencode \
    && useradd -u 1000 -g opencode -m -s /bin/bash opencode

# --- ENV vars for version managers ---
ENV NVM_DIR=/home/opencode/.nvm
ENV PYENV_ROOT=/home/opencode/.pyenv
ENV RUSTUP_HOME=/home/opencode/.rustup
ENV CARGO_HOME=/home/opencode/.cargo
ENV GVM_ROOT=/home/opencode/.gvm
ENV GOPATH=/home/opencode/go
ENV BUN_INSTALL=/home/opencode/.bun

# --- Install Node.js 20 LTS (system) for OpenCode ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Install OpenCode ---
RUN npm install -g opencode-ai

# --- Install yq v4.40.5 ---
RUN YQ_VERSION=4.40.5 \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# --- Install gh v2.42.1 ---
RUN GH_VERSION=2.42.1 \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
       -o /tmp/gh.tar.gz \
    && tar -xzf /tmp/gh.tar.gz -C /tmp \
    && mv /tmp/gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/gh \
    && rm -rf /tmp/gh.tar.gz /tmp/gh_${GH_VERSION}_linux_amd64

# --- Switch to opencode user for language runtimes ---
USER opencode

# --- Install nvm (with BuildKit cache) ---
RUN --mount=type=cache,target=/home/opencode/.nvm/.cache \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# --- Install pyenv (with BuildKit cache) ---
RUN --mount=type=cache,target=/home/opencode/.pyenv/build \
    curl -fsSL https://pyenv.run | bash

# --- Install rustup (with BuildKit cache) ---
RUN --mount=type=cache,target=/home/opencode/.rustup/registry \
    --mount=type=cache,target=/home/opencode/.cargo/registry \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path

# --- Install Go directly from go.dev ---
RUN GO_VERSION=1.24.0 \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
       -o /tmp/go.tar.gz \
    && mkdir -p /home/opencode/.local/go \
    && tar -xzf /tmp/go.tar.gz -C /home/opencode/.local/go \
    && rm -f /tmp/go.tar.gz
ENV GOROOT=/home/opencode/.local/go/go
ENV PATH="${GOROOT}/bin:${PATH}"

# --- Install gvm (Go Version Manager) ---
RUN bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer) || true

# --- Install bun for OmO ---
RUN curl -fsSL https://bun.sh/install | bash

# --- Install Oh-My-OpenAgent ---
ARG OMO_VERSION=3.14.0
# NOTE: Shell form required. Do not convert to exec form.
RUN bunx oh-my-opencode@${OMO_VERSION} install --no-tui --zai-coding-plan=yes --claude=no --openai=no --gemini=no --copilot=no

# --- Build PATH ---
ENV PATH="/home/opencode/.cargo/bin:/home/opencode/.pyenv/shims:/home/opencode/.pyenv/bin:/home/opencode/.nvm/versions/node/$(ls /home/opencode/.nvm/versions/node/ 2>/dev/null | head -1)/bin:/home/opencode/.bun/bin:/home/opencode/.local/go/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- Switch back to root for config copy and permissions ---
USER root

# --- Create default config directory ---
RUN mkdir -p /opt/opencode-defaults

# --- Copy default config files ---
COPY config/opencode.json /opt/opencode-defaults/opencode.json
COPY config/oh-my-openagent.jsonc /opt/opencode-defaults/oh-my-openagent.jsonc
COPY config/.opencode-docker-config-version /opt/opencode-defaults/.opencode-docker-config-version

# --- Copy scripts ---
COPY scripts/docker-init.sh /scripts/docker-init.sh
COPY scripts/docker-entrypoint.sh /scripts/docker-entrypoint.sh
RUN chmod +x /scripts/docker-init.sh /scripts/docker-entrypoint.sh \
    && chown -R opencode:opencode /scripts/ /opt/opencode-defaults/

# --- Expose port ---
EXPOSE 4000

# --- Healthcheck ---
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# --- Entrypoint ---
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["web"]

# --- Final user ---
USER opencode
