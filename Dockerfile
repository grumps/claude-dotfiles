# Multi-stage build to get binaries from official containers
FROM ghcr.io/terraform-linters/tflint:latest AS tflint
FROM aquasec/tfsec:latest AS tfsec
FROM alpine/helm:latest AS helm
FROM golangci/golangci-lint:latest AS golangci-lint

# Main stage
FROM public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim

# NOTE: This base image currently only supports linux/amd64
# ARM64 builds are disabled in the CI workflow until base image compatibility is resolved

# Declare build arguments for architecture-specific installations
ARG TARGETARCH

# Install core development tools and dependencies
# Using install_deb script provided by the base image
RUN install_deb \
    curl \
    wget \
    git \
    jq \
    ca-certificates \
    gnupg \
    shellcheck \
    libnotify-bin \
    build-essential \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install shfmt (shell formatter) - architecture-aware
RUN case "${TARGETARCH}" in \
    amd64) SHFMT_ARCH=amd64 ;; \
    arm64) SHFMT_ARCH=arm64 ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    wget -qO /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_${SHFMT_ARCH} && \
    chmod +x /usr/local/bin/shfmt

# Copy binaries from official containers
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY --from=golangci-lint /usr/bin/golangci-lint /usr/local/bin/golangci-lint
COPY --from=tflint /usr/local/bin/tflint /usr/local/bin/tflint
COPY --from=tfsec /usr/bin/tfsec /usr/local/bin/tfsec
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install Just (command runner)
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install kubectl - architecture-aware
RUN case "${TARGETARCH}" in \
    amd64) KUBECTL_ARCH=amd64 ;; \
    arm64) KUBECTL_ARCH=arm64 ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KUBECTL_ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && \
    mv kustomize /usr/local/bin/

# Install Python tools using uv
RUN install_deb python3-pip && \
    uv pip install --break-system-packages --system yamllint ruff mypy git-cliff && \
    rm -rf /var/lib/apt/lists/*

# Install rumdl (Rust-based markdown linter) - architecture-aware
RUN case "${TARGETARCH}" in \
    amd64) RUMDL_ARCH=x86_64-unknown-linux-musl ;; \
    arm64) RUMDL_ARCH=aarch64-unknown-linux-musl ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    wget -qO rumdl.tar.gz https://github.com/rvben/rumdl/releases/latest/download/rumdl-${RUMDL_ARCH}.tar.gz && \
    tar -xzf rumdl.tar.gz && \
    mv rumdl /usr/local/bin/rumdl && \
    chmod +x /usr/local/bin/rumdl && \
    rm rumdl.tar.gz

# Install lychee (Rust-based link checker) - architecture-aware
RUN case "${TARGETARCH}" in \
    amd64) LYCHEE_ARCH=x86_64-unknown-linux-gnu ;; \
    arm64) LYCHEE_ARCH=aarch64-unknown-linux-gnu ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    wget -qO lychee.tar.gz https://github.com/lycheeverse/lychee/releases/download/v0.15.1/lychee-v0.15.1-${LYCHEE_ARCH}.tar.gz && \
    tar -xzf lychee.tar.gz && \
    mv lychee /usr/local/bin/lychee && \
    chmod +x /usr/local/bin/lychee && \
    rm lychee.tar.gz

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    install_deb terraform && \
    rm -rf /var/lib/apt/lists/*

# Verify installations
RUN echo "=== Verifying tool installations ===" && \
    git --version && \
    jq --version && \
    shellcheck --version && \
    shfmt --version && \
    just --version && \
    helm version && \
    kubectl version --client && \
    kustomize version && \
    git-cliff --version && \
    yamllint --version && \
    golangci-lint --version && \
    ruff --version && \
    mypy --version && \
    uv --version && \
    rumdl --version && \
    lychee --version && \
    terraform --version && \
    tflint --version && \
    tfsec --version && \
    echo "=== All tools installed successfully ==="

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
