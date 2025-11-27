# CI/CD recipes for GitHub Actions and local development
# These recipes ensure local-CI parity: run the same commands locally as in CI

# Validate shell scripts with ShellCheck and shfmt
lint-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running ShellCheck..."
  shellcheck --severity=warning **/*.sh
  echo "✅ ShellCheck passed"

  echo "🔍 Checking shell formatting..."
  shfmt -d -i 2 -ci -bn **/*.sh
  echo "✅ Shell formatting check passed"

# Lint and type-check Python scripts
lint-python:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running ruff linter..."
  uvx ruff check .
  echo "✅ Ruff linting passed"

  echo "🔍 Running ruff format check..."
  uvx ruff format --check .
  echo "✅ Ruff formatting check passed"

  echo "🔍 Running mypy type checker..."
  uvx mypy scripts/*.py --strict
  echo "✅ Mypy type checking passed"

# Validate markdown files with rumdl (Rust) and check links with lychee (Rust)
lint-markdown:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running rumdl..."
  uvx rumdl check .
  echo "✅ Markdown linting passed"

  echo "🔍 Checking links with lychee..."
  lychee --config lychee.toml .
  echo "✅ Link checking passed"

# Run integration tests in Docker container (requires Docker/Podman)
test-install:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🧪 Running integration tests in Arch Linux container..."

  # Check if docker or podman is available
  if command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
  elif command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
  else
    echo "❌ Neither docker nor podman found. Please install one of them."
    exit 1
  fi

  echo "Using container runtime: $CONTAINER_CMD"

  $CONTAINER_CMD run --rm -v "$(pwd):/workspace" -w /workspace archlinux:latest /bin/bash -c '
    set -e
    echo "📦 Installing dependencies..."
    pacman -Sy --noconfirm git bats just base-devel

    echo "🏗️  Creating test repository..."
    mkdir -p /tmp/test-repo
    cd /tmp/test-repo
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    echo "📥 Running install script..."
    bash /workspace/install.sh

    echo "✅ Running installation tests..."
    bats /workspace/tests/integration/test-install.bats

    echo "🗑️  Running uninstall script..."
    bash /workspace/uninstall.sh --force

    echo "✅ Running uninstall tests..."
    bats /workspace/tests/integration/test-uninstall.bats
  '

  echo "✅ Integration tests passed"

# === Release Management Recipes ===

# Generate or update CHANGELOG.md using git-cliff (Rust-based)
changelog:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "📝 Generating changelog with git-cliff..."
  git-cliff --config cliff.toml --output CHANGELOG.md
  echo "✅ Changelog generated"

# Generate release notes for a specific tag (Argo-compatible: no GitHub dependency)
release-notes TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate semantic version tag format
  if [[ ! "{{TAG}}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid tag format: {{TAG}}" >&2
    echo "Expected format: v1.2.3" >&2
    exit 1
  fi

  # Generate changelog for this version only
  git-cliff --config cliff.toml --unreleased --tag "{{TAG}}" --strip all

# Create GitHub release using gh CLI (works locally and in any CI)
github-release TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate tag format first
  just release-notes "{{TAG}}" > /dev/null

  echo "📝 Generating release notes with git-cliff..."
  NOTES=$(just release-notes "{{TAG}}")

  echo "🚀 Creating GitHub release for {{TAG}}..."
  gh release create "{{TAG}}" \
    --title "Release {{TAG}}" \
    --notes "$NOTES" \
    install.sh uninstall.sh

  echo "✅ Release {{TAG}} created with assets"

# Full release workflow (for local testing)
release TAG: (release-notes TAG) (github-release TAG)
  @echo "✅ Release {{TAG}} complete"
