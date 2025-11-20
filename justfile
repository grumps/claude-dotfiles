# claude-dotfiles justfile
# This repository's own build and validation recipes

# Import base protocol
import? 'justfiles/_base.just'

# Import CI/CD recipes
import? 'justfiles/ci.just'

# === Required Recipes (for base protocol) ===

# Run all linters
lint: lint-shell lint-python

# Run tests (placeholder for now, will add integration tests later)
test:
  @echo "🧪 No tests defined yet"
  @echo "✅ Tests passed"

# === Custom Recipes ===

# Format shell scripts
format-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🎨 Formatting shell scripts..."
  find . -type f \( -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" \) \
    ! -path "./.git/*" \
    ! -name "*.py" \
    -exec shfmt -w -i 2 -ci -bn {} +
  echo "✅ Shell scripts formatted"
