# claude-dotfiles justfile
# This repository's own build and validation recipes

# Import base protocol
import? 'justfiles/_base.just'

# Import CI/CD recipes
import? 'justfiles/ci.just'

# === Required Recipes (for base protocol) ===

# Run all linters
lint: lint-shell lint-python lint-markdown

# Run tests (unit tests + integration tests)
test: test-unit test-integration

# Run unit tests with pytest
test-unit:
  @echo "🧪 Running unit tests..."
  uv run --with pytest --with pytest-cov pytest tests/unit -v --tb=short
  @echo "✅ Unit tests passed"

# Run integration tests
test-integration:
  @echo "🧪 Running integration tests..."
  @tests/validate-tests.sh
  @echo "✅ Integration tests passed"

# === Custom Recipes ===

# Format all files (markdown, python, shell)
fmt: fmt-markdown fmt-python fmt-shell

# Format markdown files
fmt-markdown:
  @echo "🎨 Formatting markdown files..."
  uvx rumdl fmt
  @echo "✅ Markdown files formatted"

# Format Python files
fmt-python:
  @echo "🎨 Formatting Python files..."
  uv run --with ruff ruff format .
  @echo "✅ Python files formatted"

# Format shell scripts
fmt-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🎨 Formatting shell scripts..."
  find . -type f \( -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" \) \
    ! -path "./.git/*" \
    ! -path "*/__pycache__/*" \
    ! -name "*.py" \
    ! -name "*.pyc" \
    -exec shfmt -w -i 2 -ci -bn {} +
  echo "✅ Shell scripts formatted"

# Legacy alias for shell formatting
format-shell: fmt-shell
