# Display available recipes
default:
  @just --list

# === Protocol ===
# Your justfile MUST define:
#   lint - Run linters
#   test - Run tests
#
# Your justfile SHOULD define:
#   fmt - Auto-format code (runs before lint in hooks)

# Validation entry point
validate: lint test

# === Helpers ===

# Display repository information and status
info:
  #!/usr/bin/env bash
  echo "## Repository Context"
  echo ""
  echo "**Branch:** $(git branch --show-current)"
  echo "**Status:** $(git status --short | wc -l) changed files"
  echo ""
  echo "## Changed Files"
  git diff --name-only --cached
  echo ""
  echo "## Available Just Recipes"
  just --list
  echo ""
  echo "## Recent Commits"
  git log -5 --oneline --decorate
  echo ""
  echo "## Current Diff Stats"
  git diff --cached --stat

# Check if working directory is clean
check-clean:
  #!/usr/bin/env bash
  if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Working directory is not clean"
    git status --short
    exit 1
  fi
  echo "✅ Working directory is clean"
