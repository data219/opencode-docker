# opencode-docker — OpenCode + Oh-My-OpenAgent with GLM-5
# Single-stage build with BuildKit cache mounts
# Requires: DOCKER_BUILDKIT=1

FROM debian:12.13-slim

# --- Optional language build args ---
ARG INSTALL_JAVA=false
ARG INSTALL_RUBY=false
ARG INSTALL_SWIFT=false
ARG INSTALL_ELIXIR=false
# renovate: datasource=node-version depName=node versioning=node
ARG NODE_VERSION=20.20.2
# renovate: datasource=github-releases depName=composer/composer
ARG COMPOSER_VERSION=2.9.7
# renovate: datasource=github-tags depName=pyenv/pyenv
ARG PYENV_VERSION=v2.6.27
# renovate: datasource=github-releases depName=rust-lang/rustup
ARG RUSTUP_VERSION=1.29.0
# renovate: datasource=github-releases depName=rust-lang/rust
ARG RUST_TOOLCHAIN_VERSION=1.94.1
# renovate: datasource=git-refs depName=moovweb/gvm packageName=https://github.com/moovweb/gvm
ARG GVM_REF=master
ARG GVM_COMMIT=dd652539fa4b771840846f8319fad303c7d0a8d2
# renovate: datasource=github-releases depName=oven-sh/bun
ARG BUN_VERSION=1.3.12
# renovate: datasource=github-releases depName=tianon/gosu
ARG GOSU_VERSION=1.17
# renovate: datasource=npm depName=opencode-ai
ARG OPENCODE_VERSION=1.4.3
# renovate: datasource=npm depName=agent-browser
ARG AGENT_BROWSER_VERSION=0.25.4
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.40.5
# renovate: datasource=github-releases depName=cli/cli versioning=semver
ARG GH_VERSION=2.89.0
# renovate: datasource=gitlab-tags depName=gitlab-org/cli versioning=semver
ARG GLAB_VERSION=1.92.1
# renovate: datasource=github-releases depName=BjoernSchotte/atlcli versioning=semver
ARG ATLCLI_VERSION=0.16.0
# renovate: datasource=github-tags depName=nvm-sh/nvm
ARG NVM_VERSION=v0.40.1
# renovate: datasource=golang-version depName=go
ARG GO_VERSION=1.24.0
# renovate: datasource=github-releases depName=golangci/golangci-lint
ARG GO_LINT_VERSION=1.62.0
# renovate: datasource=github-releases depName=adoptium/temurin21-binaries versioning=loose
ARG JAVA_VERSION_TAG=jdk-21.0.3+9
# renovate: datasource=ruby-version depName=ruby versioning=ruby
ARG RUBY_VERSION=3.3.6
# renovate: datasource=github-tags depName=swiftlang/swift versioning=loose
ARG SWIFT_VERSION=swift-6.0-RELEASE
# renovate: datasource=npm depName=oh-my-opencode
ARG OMO_VERSION=3.14.0

# --- System packages (with BuildKit cache for apt) ---
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
       curl git vim nano jq findutils openssh-client \
       build-essential make pkg-config autoconf bison re2c \
       unzip xz-utils ca-certificates gnupg \
       fonts-liberation wget xdg-utils \
       libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 \
       libcairo2 libcups2 libdbus-1-3 libexpat1 libgbm1 libglib2.0-0 \
       libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libudev1 libvulkan1 \
       libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
       libxkbcommon0 libxrandr2 \
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
    && curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${ARCH}" -o /usr/local/bin/gosu \
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
ENV AGENT_BROWSER_EXECUTABLE_PATH=/opt/agent-browser/chrome/chrome

# --- Install Node.js 20 LTS for OpenCode ---
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
       -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz

# --- Install OpenCode ---
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# --- Install agent-browser CLI and browser runtime ---
RUN npm install -g agent-browser@${AGENT_BROWSER_VERSION} \
    && mkdir -p /opt/opencode-browser-home/.cache /opt/agent-browser \
    && HOME=/opt/opencode-browser-home XDG_CACHE_HOME=/opt/opencode-browser-home/.cache agent-browser install \
    && browser_dir="$(find /opt/opencode-browser-home/.agent-browser/browsers -mindepth 1 -maxdepth 1 -type d | head -n 1)" \
    && mv "$browser_dir" /opt/agent-browser/chrome \
    && rm -rf /opt/opencode-browser-home

# --- Install yq v4.40.5 ---
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# --- Install GitHub/GitLab/Atlassian CLIs ---
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) gh_arch="amd64"; glab_arch="amd64"; atlcli_arch="x64" ;; \
      arm64) gh_arch="arm64"; glab_arch="arm64"; atlcli_arch="arm64" ;; \
      *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    gh_archive="gh_${GH_VERSION}_linux_${gh_arch}.tar.gz"; \
    glab_archive="glab_${GLAB_VERSION}_linux_${glab_arch}.tar.gz"; \
    atlcli_archive="atlcli-linux-${atlcli_arch}.tar.gz"; \
    install_archive() { \
      binary="$1"; \
      url="$2"; \
      checksum_url="$3"; \
      archive_name="$4"; \
      tmpdir="$(mktemp -d)"; \
      mkdir -p "${tmpdir}/unpack"; \
      curl -fsSL "${url}" -o "${tmpdir}/pkg.tgz"; \
      curl -fsSL "${checksum_url}" -o "${tmpdir}/checksums.txt"; \
      (cd "${tmpdir}" && awk -v target="${archive_name}" '$2 == target { print $1 "  " "pkg.tgz" }' checksums.txt | sha256sum -c -); \
      tar -xzf "${tmpdir}/pkg.tgz" -C "${tmpdir}/unpack"; \
      install -m 0755 "$(find "${tmpdir}/unpack" -type f -name "${binary}" | head -n 1)" "/usr/local/bin/${binary}"; \
      rm -rf "${tmpdir}"; \
    }; \
    install_archive gh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${gh_archive}" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" "${gh_archive}"; \
    install_archive glab "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/${glab_archive}" "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/checksums.txt" "${glab_archive}"; \
    install_archive atlcli "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/${atlcli_archive}" "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/checksums.txt" "${atlcli_archive}"

# --- Install Composer (needs root for /usr/local/bin) ---
RUN curl -fsSL "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
       -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

# --- Switch to opencode user for language runtimes ---
# USER opencode — entrypoint handles user switch

# --- Install nvm ---
RUN mkdir -p /home/opencode/.nvm \
    && curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# --- Install pyenv ---
RUN git clone --branch "${PYENV_VERSION}" --depth 1 https://github.com/pyenv/pyenv.git /home/opencode/.pyenv

# --- Install rustup ---
RUN mkdir -p /home/opencode/.rustup /home/opencode/.cargo \
    && curl --proto '=https' --tlsv1.2 -sSf "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
       -o /tmp/rustup-init \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --default-toolchain "${RUST_TOOLCHAIN_VERSION}" --no-modify-path \
    && rm -f /tmp/rustup-init

# --- Install Go directly from go.dev ---
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
       -o /tmp/go.tar.gz \
    && mkdir -p /home/opencode/.local/go \
    && tar -xzf /tmp/go.tar.gz -C /home/opencode/.local/go \
    && rm -f /tmp/go.tar.gz
ENV GOROOT=/home/opencode/.local/go/go
ENV PATH="${GOROOT}/bin:${PATH}"

# --- Install gvm (Go Version Manager) ---
RUN mkdir -p /home/opencode/.gvm /home/opencode/go \
    && bash -c "curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/${GVM_COMMIT}/binscripts/gvm-installer | bash" || true

# --- Install bun for OmO ---
RUN mkdir -p /home/opencode/.bun/bin \
    && curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" \
       -o /tmp/bun.zip \
    && unzip -q /tmp/bun.zip -d /tmp \
    && mv /tmp/bun-linux-x64/bun /home/opencode/.bun/bin/bun \
    && chmod +x /home/opencode/.bun/bin/bun \
    && rm -rf /tmp/bun.zip /tmp/bun-linux-x64

# --- Install golangci-lint ---
RUN curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/v${GO_LINT_VERSION}/golangci-lint-${GO_LINT_VERSION}-linux-amd64.tar.gz" \
       -o /tmp/golangci-lint.tar.gz \
    && tar -xzf /tmp/golangci-lint.tar.gz -C /tmp \
    && mv /tmp/golangci-lint-${GO_LINT_VERSION}-linux-amd64/golangci-lint /home/opencode/.local/go/go/bin/ \
    && rm -rf /tmp/golangci-lint*

# --- Optional: Java (Temurin JDK 21) ---
RUN if [ "$INSTALL_JAVA" = "true" ]; then \
      JAVA_ARCHIVE_VERSION="${JAVA_VERSION_TAG#jdk-}" \
      && JAVA_ARCHIVE_VERSION="${JAVA_ARCHIVE_VERSION/+/_}" \
      && curl -fsSL "https://github.com/adoptium/temurin21-binaries/releases/download/${JAVA_VERSION_TAG}/OpenJDK21U-jdk_x64_linux_hotspot_${JAVA_ARCHIVE_VERSION}.tar.gz" -o /tmp/openjdk.tar.gz \
      && mkdir -p /home/opencode/.local/java \
      && tar -xzf /tmp/openjdk.tar.gz -C /home/opencode/.local/java --strip-components=1 \
      && rm -f /tmp/openjdk.tar.gz; \
    fi

# --- Optional: Ruby 3.3 ---
RUN if [ "$INSTALL_RUBY" = "true" ]; then \
      curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" -o /tmp/ruby.tar.gz \
      && tar -xzf /tmp/ruby.tar.gz -C /tmp \
      && cd "/tmp/ruby-${RUBY_VERSION}" && ./configure --prefix=/home/opencode/.local/ruby && make -j"$(nproc)" && make install \
      && rm -rf /tmp/ruby*; \
    fi

# --- Optional: Swift 6.0 ---
RUN if [ "$INSTALL_SWIFT" = "true" ]; then \
      SWIFT_RELEASE="${SWIFT_VERSION#swift-}" \
      && SWIFT_RELEASE_LOWER="${SWIFT_RELEASE,,}" \
      && curl -fsSL "https://download.swift.org/swift-${SWIFT_RELEASE_LOWER}/ubuntu2404/swift-${SWIFT_RELEASE}/swift-${SWIFT_RELEASE}-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz \
      && mkdir -p /home/opencode/.local/swift \
      && tar -xzf /tmp/swift.tar.gz -C /home/opencode/.local/swift --strip-components=1 \
      && rm -f /tmp/swift.tar.gz; \
    fi

# --- Install Oh-My-OpenAgent ---
# NOTE: Shell form required. Do not convert to exec form.
# NOTE: --no-tui skips the interactive TUI prompt during Docker build (no TTY in container).
#       This does NOT affect the opencode runtime — both WebUI and TUI work at runtime.
# NOTE: OmO writes to XDG_CONFIG_HOME/opencode/. We redirect it via HOME to a temp dir,
#       then pick the agent config. Our opencode.json seed (with {env:} provider) takes priority.
RUN mkdir -p /opt/opencode-defaults \
  && HOME=/tmp/omo-install /home/opencode/.bun/bin/bun x oh-my-opencode@${OMO_VERSION} install \
    --no-tui --zai-coding-plan=yes --claude=no --openai=no --gemini=yes --copilot=no \
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
COPY bootstrap/config/opencode.json /opt/opencode-defaults/opencode.json.managed
COPY bootstrap/config/oh-my-openagent.jsonc /opt/opencode-defaults/oh-my-openagent.jsonc.managed
COPY bootstrap/config/.opencode-docker-config-version /opt/opencode-defaults/.opencode-docker-config-version

# --- Copy bootstrap skills to defaults (seeded at runtime by docker-init.sh) ---
COPY bootstrap/skills/ /opt/opencode-defaults/skills/

# --- Create volume mount points and seed with defaults ---
# These directories MUST exist in the image for Docker bind mounts to work correctly.
RUN mkdir -p /home/opencode/.config/opencode \
    /home/opencode/.config/gh \
    /home/opencode/.config/glab \
    /home/opencode/.local/share/opencode \
    /home/opencode/.local/state/opencode \
    /home/opencode/workspace \
    /home/opencode/.config/opencode/skills
RUN cp -a /opt/opencode-defaults/opencode.json.managed /home/opencode/.config/opencode/opencode.json \
  && cp -a /opt/opencode-defaults/oh-my-openagent.jsonc.managed /home/opencode/.config/opencode/oh-my-openagent.jsonc \
  && cp -a /opt/opencode-defaults/.opencode-docker-config-version /home/opencode/.config/opencode/.opencode-docker-config-version \
  && cp -a /opt/opencode-defaults/oh-my-openagent-omo.json /home/opencode/.config/opencode/oh-my-openagent-omo.json 2>/dev/null || true \
  && cp -a /opt/opencode-defaults/skills/. /home/opencode/.config/opencode/skills/
RUN chown -R opencode:opencode \
    /home/opencode/.config/opencode \
    /home/opencode/.config/gh \
    /home/opencode/.config/glab \
    /home/opencode/.local/share/opencode \
    /home/opencode/.local/state/opencode \
    /home/opencode/workspace

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
