# claude-dotfiles justfile
# This repository's own build and validation recipes

# Import base protocol
import? 'justfiles/_base.just'

# Import CI/CD recipes
import? 'justfiles/ci.just'

# Import context management recipes
import? 'justfiles/context.just'

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
  @echo "🎨 Formatting shell scripts..."
  shfmt -w -i 2 -ci -bn **/*.sh
  @echo "✅ Shell scripts formatted"

# === Version Management ===

# Bump plugin version (usage: just bump-version [major|minor|patch])
bump-version part="patch":
  #!/usr/bin/env bash
  set -euo pipefail
  PLUGIN_JSON=".claude-plugin/plugin.json"
  CURRENT=$(jq -r '.version' "$PLUGIN_JSON")
  echo "📦 Current version: $CURRENT"
  echo "📦 Bumping {{part}} version..."
  NEW_VERSION=$(echo "$CURRENT" | bumpver {{part}} -)
  echo "📦 New version: $NEW_VERSION"
  # Update the version in plugin.json
  jq --arg ver "$NEW_VERSION" '.version = $ver' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp"
  mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"
  echo "✅ Version bumped: $CURRENT → $NEW_VERSION"
  echo ""
  echo "💡 Don't forget to commit the version change:"
  echo "   git add $PLUGIN_JSON"
  echo "   git commit -m 'chore: bump plugin version to $NEW_VERSION'"
