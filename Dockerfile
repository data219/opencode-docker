# opencode-docker — OpenCode + Oh-My-OpenAgent with GLM-5
# Single-stage build with BuildKit cache mounts
# Requires: DOCKER_BUILDKIT=1

FROM debian:bookworm-slim

# --- Optional language build args ---
ARG INSTALL_JAVA=false
ARG INSTALL_RUBY=false
ARG INSTALL_SWIFT=false
ARG INSTALL_ELIXIR=false

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

# --- Install PHP via sury.org ---
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends php8.4-cli php8.4-dev php8.4-mbstring php8.4-xml php8.4-curl php8.4-sqlite3 php8.4-pgsql php8.4-intl php8.4-zip \
    && rm -rf /var/lib/apt/lists/*

# --- Optional: Elixir + Erlang/OTP 27 (requires root for apt-get) ---
RUN if [ "$INSTALL_ELIXIR" = "true" ]; then \
      apt-get update && apt-get install -y --no-install-recommends erlang elixir \
      && rm -rf /var/lib/apt/lists/*; \
    fi

# --- Create non-root user ---
RUN groupadd -g 1000 opencode \
    && useradd -u 1000 -g opencode -m -s /bin/bash opencode

# --- Install gosu for privilege drop ---
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-${ARCH}" -o /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu \
    && gosu --version

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

# --- Install Composer (needs root for /usr/local/bin) ---
RUN curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# --- Switch to opencode user for language runtimes ---
# USER opencode — entrypoint handles user switch

# --- Install nvm ---
RUN mkdir -p /home/opencode/.nvm \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# --- Install pyenv ---
RUN curl -fsSL https://pyenv.run | bash

# --- Install rustup ---
RUN mkdir -p /home/opencode/.rustup /home/opencode/.cargo \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path

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
RUN mkdir -p /home/opencode/.gvm /home/opencode/go \
    && bash -c 'bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer))' || true

# --- Install bun for OmO ---
RUN mkdir -p /home/opencode/.bun \
    && curl -fsSL https://bun.sh/install | bash

# --- Install golangci-lint ---
RUN GO_LINT_VERSION=1.62.0 \
    && curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/v${GO_LINT_VERSION}/golangci-lint-${GO_LINT_VERSION}-linux-amd64.tar.gz" \
       -o /tmp/golangci-lint.tar.gz \
    && tar -xzf /tmp/golangci-lint.tar.gz -C /tmp \
    && mv /tmp/golangci-lint-${GO_LINT_VERSION}-linux-amd64/golangci-lint /home/opencode/.local/go/go/bin/ \
    && rm -rf /tmp/golangci-lint*

# --- Optional: Java (Temurin JDK 21) ---
RUN if [ "$INSTALL_JAVA" = "true" ]; then \
      curl -fsSL https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.3%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.3_9.tar.gz -o /tmp/openjdk.tar.gz \
      && mkdir -p /home/opencode/.local/java \
      && tar -xzf /tmp/openjdk.tar.gz -C /home/opencode/.local/java --strip-components=1 \
      && rm -f /tmp/openjdk.tar.gz; \
    fi

# --- Optional: Ruby 3.3 ---
RUN if [ "$INSTALL_RUBY" = "true" ]; then \
      curl -fsSL https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.6.tar.gz -o /tmp/ruby.tar.gz \
      && tar -xzf /tmp/ruby.tar.gz -C /tmp \
      && cd /tmp/ruby-3.3.6 && ./configure --prefix=/home/opencode/.local/ruby && make -j"$(nproc)" && make install \
      && rm -rf /tmp/ruby*; \
    fi

# --- Optional: Swift 6.0 ---
RUN if [ "$INSTALL_SWIFT" = "true" ]; then \
      curl -fsSL https://download.swift.org/swift-6.0-release/ubuntu2404/swift-6.0-RELEASE/swift-6.0-RELEASE-ubuntu24.04.tar.gz -o /tmp/swift.tar.gz \
      && mkdir -p /home/opencode/.local/swift \
      && tar -xzf /tmp/swift.tar.gz -C /home/opencode/.local/swift --strip-components=1 \
      && rm -f /tmp/swift.tar.gz; \
    fi

# --- Install Oh-My-OpenAgent ---
ARG OMO_VERSION=3.14.0
# NOTE: Shell form required. Do not convert to exec form.
# NOTE: --no-tui skips the interactive TUI prompt during Docker build (no TTY in container).
#       This does NOT affect the opencode runtime — both WebUI and TUI work at runtime.
# NOTE: OmO writes to XDG_CONFIG_HOME/opencode/. We redirect it via HOME to a temp dir,
#       then pick the agent config. Our opencode.json seed (with {env:} provider) takes priority.
RUN mkdir -p /opt/opencode-defaults \
  && HOME=/tmp/omo-install /home/opencode/.bun/bin/bunx oh-my-opencode@${OMO_VERSION} install \
    --no-tui --zai-coding-plan=yes --claude=no --openai=no --gemini=no --copilot=no \
  && cp /tmp/omo-install/.config/opencode/oh-my-opencode.json /opt/opencode-defaults/oh-my-openagent-omo.json \
  && rm -rf /tmp/omo-install

# --- Build PATH ---
ENV PATH="/home/opencode/.cargo/bin:/home/opencode/.pyenv/shims:/home/opencode/.pyenv/bin:/home/opencode/.nvm/versions/node/$(ls /home/opencode/.nvm/versions/node/ 2>/dev/null | head -1)/bin:/home/opencode/.bun/bin:/home/opencode/.local/go/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- Switch back to root for config copy and permissions ---
USER root

# --- Create default config directory ---
RUN mkdir -p /opt/opencode-defaults

# --- Copy default config files ---
# Managed files (.managed suffix) are always overwritten on version upgrade.
# Non-managed copies serve as initial seed only (first start with empty volume).
COPY config/opencode.json /opt/opencode-defaults/opencode.json.managed
COPY config/oh-my-openagent.jsonc /opt/opencode-defaults/oh-my-openagent.jsonc.managed
COPY config/.opencode-docker-config-version /opt/opencode-defaults/.opencode-docker-config-version

# --- Create volume mount points and seed with defaults ---
# These directories MUST exist in the image for Docker bind mounts to work correctly.
RUN mkdir -p /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode \
    /home/opencode/.local/state/opencode \
    /home/opencode/workspace \
    /home/opencode/.agents/skills \
  && cp -a /opt/opencode-defaults/opencode.json.managed /home/opencode/.config/opencode/opencode.json \
  && cp -a /opt/opencode-defaults/oh-my-openagent.jsonc.managed /home/opencode/.config/opencode/oh-my-openagent.jsonc \
  && cp -a /opt/opencode-defaults/.opencode-docker-config-version /home/opencode/.config/opencode/.opencode-docker-config-version \
  && cp -a /opt/opencode-defaults/oh-my-openagent-omo.json /home/opencode/.config/opencode/oh-my-openagent-omo.json 2>/dev/null || true \
  && chown -R opencode:opencode /home/opencode

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
# USER opencode — entrypoint handles user switch
