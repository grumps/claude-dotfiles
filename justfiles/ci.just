# CI/CD recipes for GitHub Actions and local development
# These recipes ensure local-CI parity: run the same commands locally as in CI

# Validate shell scripts with ShellCheck and shfmt
lint-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running ShellCheck..."
  find . -type f \( -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" \) \
    ! -path "./.git/*" \
    ! -name "*.py" \
    -exec shellcheck --severity=warning {} +
  echo "✅ ShellCheck passed"

  echo "🔍 Checking shell formatting..."
  find . -type f \( -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" \) \
    ! -path "./.git/*" \
    ! -name "*.py" \
    -exec shfmt -d -i 2 -ci -bn {} +
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
