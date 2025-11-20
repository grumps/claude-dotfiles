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
