# opencode-docker — OpenCode + Oh-My-OpenAgent with GLM-5
# Single-stage build with BuildKit cache mounts
# Requires: DOCKER_BUILDKIT=1

FROM debian:13.5-slim

# --- Optional language build args ---
ARG INSTALL_JAVA=false
ARG INSTALL_RUBY=false
ARG INSTALL_SWIFT=false
ARG INSTALL_ELIXIR=false
ARG INSTALL_NVM=false
# renovate: datasource=node-version depName=node versioning=node
ARG NODE_VERSION=24.15.0
# renovate: datasource=github-releases depName=composer/composer
ARG COMPOSER_VERSION=2.9.8
# renovate: datasource=github-tags depName=pyenv/pyenv extractVersion=^v(?<version>\d+\.\d+\.\d+)$
ARG PYENV_VERSION=2.6.31
# renovate: datasource=github-releases depName=rust-lang/rustup
ARG RUSTUP_VERSION=1.29.0
# renovate: datasource=github-releases depName=rust-lang/rust
ARG RUST_TOOLCHAIN_VERSION=1.95.0
# renovate: datasource=git-refs depName=moovweb/gvm packageName=https://github.com/moovweb/gvm
ARG GVM_REF=master
ARG GVM_COMMIT=dd652539fa4b771840846f8319fad303c7d0a8d2
# renovate: datasource=github-releases depName=oven-sh/bun
ARG BUN_VERSION=1.3.12
# renovate: datasource=github-releases depName=tianon/gosu
ARG GOSU_VERSION=1.19
# renovate: datasource=npm depName=opencode-ai
ARG OPENCODE_VERSION=1.15.5
# renovate: datasource=npm depName=agent-browser
ARG AGENT_BROWSER_VERSION=0.27.0
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.53.2
# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION=1.15.3
# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>\d+\.\d+\.\d+)$
ARG KUBECTL_VERSION=1.36.1
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>\d+\.\d+\.\d+)$
ARG HELM_VERSION=4.2.0
# renovate: datasource=github-releases depName=cli/cli versioning=semver
ARG GH_VERSION=2.92.0
# renovate: datasource=gitlab-tags depName=gitlab-org/cli versioning=semver
ARG GLAB_VERSION=1.97.0
# renovate: datasource=github-releases depName=contabo/cntb versioning=semver
ARG CNTB_VERSION=1.6
# renovate: datasource=github-releases depName=cloudflare/cloudflared versioning=semver
ARG CLOUDFLARED_VERSION=2026.5.0
# renovate: datasource=github-releases depName=moby/moby versioning=semver
ARG DOCKER_CLI_VERSION=29.4.1
# renovate: datasource=github-releases depName=docker/compose versioning=semver
ARG DOCKER_COMPOSE_VERSION=5.1.3
# renovate: datasource=github-releases depName=BjoernSchotte/atlcli versioning=semver
ARG ATLCLI_VERSION=0.17.0
# renovate: datasource=github-tags depName=nvm-sh/nvm extractVersion=^v(?<version>\d+\.\d+\.\d+)$
ARG NVM_VERSION=0.40.4
# renovate: datasource=golang-version depName=go
ARG GO_VERSION=1.26.3
# renovate: datasource=github-releases depName=golangci/golangci-lint
ARG GO_LINT_VERSION=2.12.2
# renovate: datasource=github-releases depName=adoptium/temurin21-binaries versioning=semver extractVersion=^jdk-(?<version>.+)$
ARG JAVA_VERSION=21.0.11+10
# renovate: datasource=ruby-version depName=ruby versioning=ruby
ARG RUBY_VERSION=4.0.5
# renovate: datasource=github-tags depName=swiftlang/swift versioning=semver-coerced extractVersion=^swift-(?<version>.+)-RELEASE$
ARG SWIFT_VERSION=6.3.2
# renovate: datasource=npm depName=oh-my-opencode
ARG OMO_VERSION=4.2.3

# --- System packages (with BuildKit cache for apt) ---
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
       curl git vim nano jq findutils openssh-client \
       python3 python3-pip python3-venv python-is-python3 \
       build-essential make pkg-config autoconf bison re2c \
       unzip xz-utils ca-certificates gnupg ghostscript \
       fonts-liberation wget xdg-utils \
       libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 \
       libcairo2 libcups2 libdbus-1-3 libexpat1 libgbm1 libglib2.0-0 \
       libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libudev1 libvulkan1 \
       libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
       libxkbcommon0 libxrandr2 \
       libssl-dev libcurl4-openssl-dev libxml2-dev \
       libpq-dev libsqlite3-dev libffi-dev libzip-dev \
       libicu-dev libonig-dev sqlite3 zip \
       ansible-core shellcheck rsync \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/debconf/* \
    && rm -rf /usr/lib/python3.13/test \
    && find /usr/lib/python3* -type d -name '__pycache__' -prune -exec rm -rf {} + \
    && if [ -d /usr/local/lib ]; then find /usr/local/lib -type d -name '__pycache__' -prune -exec rm -rf {} +; fi

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
    && curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${ARCH}" -o /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu \
    && gosu --version

# --- Install Docker CLI + Compose plugin (client only; daemon access is opt-in at runtime) ---
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) docker_arch="x86_64" ;; \
      arm64) docker_arch="aarch64" ;; \
      *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://download.docker.com/linux/static/stable/${docker_arch}/docker-${DOCKER_CLI_VERSION}.tgz" \
      -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp docker/docker; \
    install -m 0755 /tmp/docker/docker /usr/local/bin/docker; \
    mkdir -p /usr/local/lib/docker/cli-plugins; \
    curl -fsSL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${docker_arch}" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose; \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose; \
    docker --version; \
    docker compose version; \
    rm -rf /tmp/docker /tmp/docker.tgz

# --- ENV vars for version managers ---
ENV NVM_DIR=/opt/nvm
ENV PYENV_ROOT=/home/opencode/.pyenv
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
ENV GVM_ROOT=/home/opencode/.gvm
ENV GOPATH=/home/opencode/go
ENV AGENT_BROWSER_EXECUTABLE_PATH=/opt/agent-browser/chrome/chrome

# --- Install Node.js for OpenCode ---
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
       -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz \
    && rm -rf /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/man

# --- Install OpenCode ---
RUN npm install -g opencode-ai@${OPENCODE_VERSION} \
    && npm cache clean --force \
    && rm -rf /root/.npm

# renovate: datasource=npm depName=@openchamber/web
ARG OPENCHAMBER_VERSION=1.11.3

# --- Install OpenChamber (alternative Web GUI for OpenCode) ---
RUN npm install -g @openchamber/web@${OPENCHAMBER_VERSION} \
    && npm cache clean --force \
    && rm -rf /root/.npm

# --- Install agent-browser CLI and browser runtime ---
RUN npm install -g agent-browser@${AGENT_BROWSER_VERSION} \
    && mkdir -p /opt/opencode-browser-home/.cache /opt/agent-browser \
    && HOME=/opt/opencode-browser-home XDG_CACHE_HOME=/opt/opencode-browser-home/.cache agent-browser install \
    && browser_dir="$(find /opt/opencode-browser-home/.agent-browser/browsers -mindepth 1 -maxdepth 1 -type d | head -n 1)" \
    && mv "$browser_dir" /opt/agent-browser/chrome \
    && npm cache clean --force \
    && rm -rf /opt/opencode-browser-home /root/.npm

# --- Install GitHub/GitLab/Contabo/Atlassian and platform CLIs ---
RUN --mount=type=secret,id=github_token,required=false \
    --mount=type=secret,id=github_token_alt,required=false \
    set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) common_arch="amd64"; atlcli_arch="x64"; hashicorp_arch="amd64" ;; \
      arm64) common_arch="arm64"; atlcli_arch="arm64"; hashicorp_arch="arm64" ;; \
      *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    gh_archive="gh_${GH_VERSION}_linux_${common_arch}.tar.gz"; \
    glab_archive="glab_${GLAB_VERSION}_linux_${common_arch}.tar.gz"; \
    cntb_archive="cntb_v${CNTB_VERSION}_linux_${common_arch}.tar.gz"; \
    atlcli_archive="atlcli-linux-${atlcli_arch}.tar.gz"; \
    terraform_archive="terraform_${TERRAFORM_VERSION}_linux_${hashicorp_arch}.zip"; \
    helm_archive="helm-v${HELM_VERSION}-linux-${common_arch}.tar.gz"; \
    curl_download() { \
      url="$1"; \
      output="$2"; \
      token_file=""; \
      case "${url}" in \
        https://github.com/*|https://api.github.com/*) \
          if [ -s /run/secrets/github_token ]; then token_file=/run/secrets/github_token; \
          elif [ -s /run/secrets/github_token_alt ]; then token_file=/run/secrets/github_token_alt; \
          fi; \
          if [ -n "${token_file}" ]; then \
            set +x; \
            github_token="$(tr -d '\r\n' < "${token_file}")"; \
            if [ -n "${github_token}" ]; then \
              set +e; \
              curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 20 --max-time 180 --speed-limit 1024 --speed-time 60 -H "Authorization: Bearer ${github_token}" "${url}" -o "${output}"; \
              curl_status="$?"; \
              set -e; \
              github_token=""; \
              set -x; \
              if [ "${curl_status}" -eq 0 ]; then return 0; fi; \
            fi; \
            set -x; \
          fi; \
          ;; \
      esac; \
      curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 20 --max-time 180 --speed-limit 1024 --speed-time 60 "${url}" -o "${output}"; \
    }; \
    verify_checksum_entry() { \
      checksum_archive="$1"; \
      checksum_package="$2"; \
      checksum_source="$3"; \
      checksum_expected="$4"; \
      awk -v target="${checksum_archive}" -v package="${checksum_package}" '$2 == target { print $1 "  " package }' "${checksum_source}" > "${checksum_expected}"; \
      if [ ! -s "${checksum_expected}" ]; then \
        echo "checksum entry not found for ${checksum_archive} in ${tmpdir}/${checksum_source}" >&2; \
        return 1; \
      fi; \
      sha256sum -c "${checksum_expected}"; \
    }; \
    install_archive() { \
      binary="$1"; \
      url="$2"; \
      checksum_url="$3"; \
      archive_name="$4"; \
      tmpdir="$(mktemp -d)"; \
      mkdir -p "${tmpdir}/unpack"; \
      curl_download "${url}" "${tmpdir}/pkg.tgz"; \
      curl_download "${checksum_url}" "${tmpdir}/checksums.txt"; \
      (cd "${tmpdir}" && verify_checksum_entry "${archive_name}" pkg.tgz checksums.txt pkg.tgz.sha256); \
      tar -xzf "${tmpdir}/pkg.tgz" -C "${tmpdir}/unpack"; \
      install -m 0755 "$(find "${tmpdir}/unpack" -type f -name "${binary}" | head -n 1)" "/usr/local/bin/${binary}"; \
      rm -rf "${tmpdir}"; \
    }; \
    install_zip() { \
      binary="$1"; \
      url="$2"; \
      checksum_url="$3"; \
      archive_name="$4"; \
      tmpdir="$(mktemp -d)"; \
      mkdir -p "${tmpdir}/unpack"; \
      curl_download "${url}" "${tmpdir}/pkg.zip"; \
      curl_download "${checksum_url}" "${tmpdir}/checksums.txt"; \
      (cd "${tmpdir}" && verify_checksum_entry "${archive_name}" pkg.zip checksums.txt pkg.zip.sha256); \
      unzip -q "${tmpdir}/pkg.zip" -d "${tmpdir}/unpack"; \
      install -m 0755 "$(find "${tmpdir}/unpack" -type f -name "${binary}" | head -n 1)" "/usr/local/bin/${binary}"; \
      rm -rf "${tmpdir}"; \
    }; \
    install_binary() { \
      binary="$1"; \
      url="$2"; \
      curl_download "${url}" "/usr/local/bin/${binary}"; \
      chmod +x "/usr/local/bin/${binary}"; \
    }; \
    install_kubectl() { \
      kubectl_minor="${KUBECTL_VERSION%.*}"; \
      tmpdir="$(mktemp -d)"; \
      install -d -m 0755 /etc/apt/keyrings; \
      curl_download "https://pkgs.k8s.io/core:/stable:/v${kubectl_minor}/deb/Release.key" "${tmpdir}/kubernetes-apt-keyring.gpg"; \
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg "${tmpdir}/kubernetes-apt-keyring.gpg"; \
      echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${kubectl_minor}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list; \
      apt-get update; \
      apt-get install -y --no-install-recommends "kubectl=${KUBECTL_VERSION}-*"; \
      rm -rf /var/lib/apt/lists/* "${tmpdir}"; \
    }; \
    install_binary yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${common_arch}"; \
    install_binary cloudflared "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${common_arch}"; \
    install_zip terraform "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${terraform_archive}" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" "${terraform_archive}"; \
    install_kubectl; \
    install_archive helm "https://get.helm.sh/${helm_archive}" "https://get.helm.sh/${helm_archive}.sha256sum" "${helm_archive}"; \
    install_archive gh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${gh_archive}" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" "${gh_archive}"; \
    install_archive glab "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/${glab_archive}" "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/checksums.txt" "${glab_archive}"; \
    install_archive cntb "https://github.com/contabo/cntb/releases/download/v${CNTB_VERSION}/${cntb_archive}" "https://github.com/contabo/cntb/releases/download/v${CNTB_VERSION}/checksums.txt" "${cntb_archive}"; \
    install_archive atlcli "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/${atlcli_archive}" "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/checksums.txt" "${atlcli_archive}"; \
    yq --version; \
    cloudflared --version; \
    terraform version; \
    kubectl version --client=true; \
    helm version --short; \
    gh --version | head -n 1; \
    glab --version; \
    cntb version; \
    atlcli --version

# --- Install Composer (needs root for /usr/local/bin) ---
RUN curl -fsSL "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
       -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

# --- Switch to opencode user for language runtimes ---
# USER opencode — entrypoint handles user switch

# --- Install nvm ---
RUN mkdir -p "$NVM_DIR" \
    && if [ "$INSTALL_NVM" = "true" ]; then \
         curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
         && . "$NVM_DIR/nvm.sh" \
         && nvm install "${NODE_VERSION}" \
         && nvm alias default "${NODE_VERSION}" \
         && nvm cache clear \
         && npm cache clean --force; \
       fi \
    && rm -rf /root/.npm "$NVM_DIR/.cache"

# --- Install pyenv ---
RUN git clone --branch "${PYENV_VERSION}" --depth 1 https://github.com/pyenv/pyenv.git /home/opencode/.pyenv \
    && rm -rf /home/opencode/.pyenv/.git /home/opencode/.pyenv/test /home/opencode/.pyenv/plugins/python-build/test

# --- Install Go directly from go.dev ---
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
       -o /tmp/go.tar.gz \
    && mkdir -p /opt/go \
    && tar -xzf /tmp/go.tar.gz -C /opt/go --strip-components=1 \
    && rm -f /tmp/go.tar.gz \
    && rm -rf /opt/go/test
ENV GOROOT=/opt/go
ENV PATH="${GOROOT}/bin:${PATH}"

# --- Install gvm (Go Version Manager) ---
RUN mkdir -p /home/opencode/.gvm /home/opencode/go \
    && bash -c "curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/${GVM_COMMIT}/binscripts/gvm-installer | bash" || true

# --- Install golangci-lint ---
RUN curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/v${GO_LINT_VERSION}/golangci-lint-${GO_LINT_VERSION}-linux-amd64.tar.gz" \
       -o /tmp/golangci-lint.tar.gz \
    && tar -xzf /tmp/golangci-lint.tar.gz -C /tmp \
    && mv /tmp/golangci-lint-${GO_LINT_VERSION}-linux-amd64/golangci-lint /opt/go/bin/ \
    && rm -rf /tmp/golangci-lint*

# --- Optional: Java (Temurin JDK 21) ---
RUN if [ "$INSTALL_JAVA" = "true" ]; then \
      JAVA_VERSION_TAG="jdk-${JAVA_VERSION}" \
      && JAVA_ARCHIVE_VERSION="${JAVA_VERSION/+/_}" \
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
      SWIFT_RELEASE="${SWIFT_VERSION}-RELEASE" \
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
# NOTE: We install OmO normally to /home/opencode. After install, we rename the
#       auto-generated config so our custom bootstrap config (placed later by COPY) takes priority.
RUN mkdir -p /opt/opencode-defaults \
  && mkdir -p /home/opencode/.config/opencode \
  && mkdir -p /tmp/bun-install/bin \
  && curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" \
    -o /tmp/bun.zip \
  && unzip -q /tmp/bun.zip -d /tmp \
  && mv /tmp/bun-linux-x64/bun /tmp/bun-install/bin/bun \
  && chmod +x /tmp/bun-install/bin/bun \
  && HOME=/home/opencode BUN_INSTALL=/tmp/bun-install /tmp/bun-install/bin/bun x oh-my-opencode@${OMO_VERSION} install \
    --no-tui --zai-coding-plan=yes --claude=no --openai=no --gemini=yes --copilot=no \
  && if [ -f /home/opencode/.config/opencode/opencode.json ]; then \
       mv /home/opencode/.config/opencode/opencode.json /opt/opencode-defaults/omo-generated-opencode.json; \
     fi \
  && if [ -f /home/opencode/.config/opencode/oh-my-opencode.json ]; then \
       mv /home/opencode/.config/opencode/oh-my-opencode.json /opt/opencode-defaults/omo-generated-oh-my-opencode.json; \
     fi \
  && if [ -f /home/opencode/.config/opencode/oh-my-openagent.json ]; then \
       mv /home/opencode/.config/opencode/oh-my-openagent.json /opt/opencode-defaults/omo-generated-oh-my-openagent.json; \
     fi \
  && if [ -f /home/opencode/.config/opencode/oh-my-openagent.jsonc ]; then \
       mv /home/opencode/.config/opencode/oh-my-openagent.jsonc /opt/opencode-defaults/omo-generated-oh-my-openagent.jsonc; \
     fi \
  && rm -rf \
    /tmp/bun-install \
    /tmp/bun.zip \
    /tmp/bun-linux-x64 \
    /tmp/bunx-* \
    /tmp/node-compile-cache \
    /root/.bun \
    /root/.cache

# --- Optional: Rust via rustup ---
ARG INSTALL_RUST=false
RUN install -d -o opencode -g opencode "$RUSTUP_HOME" "$CARGO_HOME" \
    && if [ "$INSTALL_RUST" = "true" ]; then \
         curl --proto '=https' --tlsv1.2 -sSf "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
           -o /tmp/rustup-init \
         && chmod +x /tmp/rustup-init \
         && HOME=/home/opencode gosu opencode /tmp/rustup-init -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN_VERSION}" --no-modify-path \
         && rm -f /tmp/rustup-init; \
       fi

# --- Build PATH ---
ENV PATH="/opt/cargo/bin:/opt/nvm/versions/node/v${NODE_VERSION}/bin:/home/opencode/.pyenv/shims:/home/opencode/.pyenv/bin:/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN printf '%s\n' \
    'export NVM_DIR=/opt/nvm' \
    'export RUSTUP_HOME=/opt/rustup' \
    'export CARGO_HOME=/opt/cargo' \
    'export GOROOT=/opt/go' \
    'export GOPATH=/home/opencode/go' \
    "export PATH=\"/opt/cargo/bin:/opt/nvm/versions/node/v${NODE_VERSION}/bin:/home/opencode/.pyenv/shims:/home/opencode/.pyenv/bin:/opt/go/bin:\$PATH\"" \
    > /etc/profile.d/opencode-toolchains.sh

# --- Switch back to root for config copy and permissions ---
USER root

# --- Create default config directory ---
RUN mkdir -p /opt/opencode-defaults

# --- Copy default config files ---
# Managed files (.managed suffix) are always overwritten on version upgrade.
# Non-managed copies serve as initial seed only (first start with empty volume).
COPY bootstrap/config/opencode.json /opt/opencode-defaults/opencode.json.managed
COPY bootstrap/config/oh-my-openagent.jsonc /opt/opencode-defaults/oh-my-openagent.jsonc.managed
COPY bootstrap/config/AGENTS.md /opt/opencode-defaults/AGENTS.md.managed
COPY bootstrap/config/.opencode-docker-config-version /opt/opencode-defaults/.opencode-docker-config-version
COPY bootstrap/config/.gitmessage /opt/opencode-defaults/.gitmessage

# --- Copy bootstrap skills to defaults (seeded at runtime by docker-init.sh) ---
COPY bootstrap/skills/ /opt/opencode-defaults/skills/

# --- Copy bootstrap OmO teams to defaults (seeded at runtime by docker-init.sh) ---
COPY bootstrap/omo/ /opt/omo-defaults/

# --- Create volume mount points and seed with defaults ---
# These directories MUST exist in the image for Docker bind mounts to work correctly.
RUN mkdir -p /home/opencode/.config/opencode \
    /home/opencode/.config/gh \
    /home/opencode/.config/glab \
    /home/opencode/.omo/teams \
    /home/opencode/.local/share/opencode \
    /home/opencode/.local/state/opencode \
    /home/opencode/workspace \
    /home/opencode/.config/opencode/skills
RUN cp -a /opt/opencode-defaults/opencode.json.managed /home/opencode/.config/opencode/opencode.json \
  && cp -a /opt/opencode-defaults/oh-my-openagent.jsonc.managed /home/opencode/.config/opencode/oh-my-openagent.jsonc \
  && cp -a /opt/opencode-defaults/AGENTS.md.managed /home/opencode/.config/opencode/AGENTS.md \
  && cp -a /opt/opencode-defaults/.opencode-docker-config-version /home/opencode/.config/opencode/.opencode-docker-config-version \
  && cp -a /opt/opencode-defaults/.gitmessage /home/opencode/.gitmessage \
  && if [ -f /opt/opencode-defaults/omo-generated-oh-my-opencode.json ]; then cp -a /opt/opencode-defaults/omo-generated-oh-my-opencode.json /home/opencode/.config/opencode/omo-generated-oh-my-opencode.json; fi \
  && if [ -f /opt/opencode-defaults/omo-generated-oh-my-openagent.json ]; then cp -a /opt/opencode-defaults/omo-generated-oh-my-openagent.json /home/opencode/.config/opencode/omo-generated-oh-my-openagent.json; fi \
  && if [ -f /opt/opencode-defaults/omo-generated-oh-my-openagent.jsonc ]; then cp -a /opt/opencode-defaults/omo-generated-oh-my-openagent.jsonc /home/opencode/.config/opencode/omo-generated-oh-my-openagent.jsonc; fi \
  && cp -a /opt/opencode-defaults/skills/. /home/opencode/.config/opencode/skills/ \
  && cp -a /opt/omo-defaults/teams/. /home/opencode/.omo/teams/
RUN chown -R opencode:opencode \
    /home/opencode/.gitmessage \
    /home/opencode/.config/opencode \
    /home/opencode/.config/gh \
    /home/opencode/.config/glab \
    /home/opencode/.omo \
    /home/opencode/.local/share/opencode \
    /home/opencode/.local/state/opencode \
    /home/opencode/workspace

# --- Snapshot home directory for non-destructive seeding at runtime ---
# rsync --ignore-existing at container start will merge this into the bind-mounted home,
# filling in missing files without overwriting existing ones.
# Uses --chown to set ownership during copy instead of a separate chown -R layer
# to avoid a large metadata-only Docker layer from recursive ownership rewrite.
RUN mkdir -p /opt/opencode-default-home \
    && rsync -a --chown=opencode:opencode --exclude='.ssh' /home/opencode/ /opt/opencode-default-home/

# --- Copy scripts ---
COPY scripts/docker-init.sh /scripts/docker-init.sh
COPY scripts/docker-entrypoint.sh /scripts/docker-entrypoint.sh
RUN chmod +x /scripts/docker-init.sh /scripts/docker-entrypoint.sh \
    && chown -R opencode:opencode /scripts/ /opt/opencode-defaults/

# --- Expose port ---
EXPOSE 4000 4020

# --- Healthcheck ---
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# --- Entrypoint ---
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["web"]

# --- Final user ---
# Final runtime user is selected in the entrypoint via gosu.
