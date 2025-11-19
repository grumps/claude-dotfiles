FROM public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim

# Install core development tools and dependencies
# Using install_deb script provided by the base image
RUN install_deb \
    # Core utilities \
    curl \
    wget \
    git \
    jq \
    ca-certificates \
    gnupg \
    # Shell scripting tools \
    shellcheck \
    # Notification support \
    libnotify-bin \
    # Build essentials for potential compilation \
    build-essential \
    # Additional utilities \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install shfmt (shell formatter)
RUN wget -qO /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64 && \
    chmod +x /usr/local/bin/shfmt

# Install Just (command runner)
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && \
    mv kustomize /usr/local/bin/

# Install yamllint
RUN install_deb python3-pip && \
    pip3 install --no-cache-dir yamllint --break-system-packages && \
    rm -rf /var/lib/apt/lists/*

# Install Go tools (golangci-lint)
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.55.2

# Install Python tools (ruff)
RUN pip3 install --no-cache-dir ruff --break-system-packages

# Install Terraform tools
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    install_deb terraform && \
    rm -rf /var/lib/apt/lists/*

# Install tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install tfsec
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

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
    yamllint --version && \
    golangci-lint --version && \
    ruff --version && \
    terraform --version && \
    tflint --version && \
    tfsec --version && \
    echo "=== All tools installed successfully ==="

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
