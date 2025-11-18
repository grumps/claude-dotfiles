#!/usr/bin/env bash
set -e

# Get the directory where this script is located (the dotfiles repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"

# Parse arguments
GLOBAL_INSTALL=false
if [ "$1" = "--global" ]; then
    GLOBAL_INSTALL=true
fi

# Set target directory based on mode
if [ "$GLOBAL_INSTALL" = true ]; then
    CLAUDE_DIR="${HOME}/.claude"
    INSTALL_MODE="global"
    echo "🌍 Installing Claude dotfiles globally..."
else
    CLAUDE_DIR=".claude"
    INSTALL_MODE="local"
    echo "🚀 Installing Claude dotfiles integration..."

    # Check if we're in a git repo (only required for local install)
    if [ ! -d ".git" ]; then
        echo "❌ Not in a git repository. Run this from your repo root."
        echo ""
        echo "💡 To install globally instead, use: $0 --global"
        exit 1
    fi

    # Verify we're not trying to install into the dotfiles repo itself
    if [ "$(pwd)" = "$DOTFILES_DIR" ]; then
        echo "❌ Cannot install into the dotfiles repository itself"
        echo "   Run this script from the target repository where you want to use the dotfiles"
        echo ""
        echo "💡 To install globally instead, use: $0 --global"
        exit 1
    fi
fi

echo "📍 Using dotfiles from: $DOTFILES_DIR"
echo "📁 Installing to: $CLAUDE_DIR"
echo ""

# 1. Create justfile if it doesn't exist (local install only)
if [ "$GLOBAL_INSTALL" = false ]; then
    if [ ! -f "justfile" ]; then
        echo "📝 Creating justfile..."
        cat > justfile << EOF
# Import base protocol from claude-dotfiles
import? '$DOTFILES_DIR/justfiles/_base.just'

# Import plan worktree management recipes (optional)
import? '$DOTFILES_DIR/justfiles/plans.just'

# === Required Recipes ===
# The imported _base.just defines \`validate: lint test\`
# You MUST implement lint and test, or validation will fail

# Uncomment and customize for your project:

# lint:
#   golangci-lint run ./...
#   ruff check .
#   yamllint .

# test:
#   go test -race -cover ./...
#   pytest -v

# === Custom Recipes ===

# Add your repository-specific recipes below
EOF
        echo "✅ Created justfile"
    else
        echo "⏭️  justfile already exists, skipping"
    fi
fi

# 2. Create .claude directory structure
echo "📁 Creating Claude directory..."
mkdir -p "$CLAUDE_DIR"/{commands,prompts,plans}

# 2a. Symlink scripts directory (local install only)
if [ "$GLOBAL_INSTALL" = false ]; then
    if [ ! -e "scripts" ]; then
        echo "🔗 Symlinking scripts directory..."
        ln -s "$DOTFILES_DIR/scripts" scripts
        echo "✅ Linked scripts directory"
    else
        echo "⏭️  scripts directory already exists"
    fi
fi

# 3. Symlink slash commands
echo "⚡ Symlinking slash commands..."
for command in "$DOTFILES_DIR/commands"/*.md; do
    filename=$(basename "$command")
    target="$CLAUDE_DIR/commands/$filename"
    if [ ! -e "$target" ]; then
        ln -s "$command" "$target"
        echo "✅ Linked $filename"
    else
        echo "⏭️  $filename already exists"
    fi
done

# 4. Symlink prompt templates
echo "📋 Symlinking prompt templates..."
for template in "$DOTFILES_DIR/prompts"/*.md; do
    filename=$(basename "$template")
    target="$CLAUDE_DIR/prompts/$filename"
    if [ ! -e "$target" ]; then
        ln -s "$template" "$target"
        echo "✅ Linked $filename"
    else
        echo "⏭️  $filename already exists"
    fi
done

# 5. Set up git hooks (local install only)
if [ "$GLOBAL_INSTALL" = false ]; then
    echo "🪝 Setting up git hooks..."
    mkdir -p .git/hooks

    # Pre-commit hook
    if [ ! -f ".git/hooks/pre-commit" ]; then
        ln -s "$DOTFILES_DIR/hooks/pre-commit" .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
        echo "✅ Installed pre-commit hook"
    else
        echo "⏭️  pre-commit hook already exists"
    fi

    # Prepare-commit-msg hook (optional, not enabled by default)
    if [ ! -f ".git/hooks/prepare-commit-msg" ]; then
        cp "$DOTFILES_DIR/hooks/prepare-commit-msg" .git/hooks/prepare-commit-msg
        # Don't make it executable - user can enable later
        echo "✅ Copied prepare-commit-msg hook (disabled by default)"
        echo "   Enable with: chmod +x .git/hooks/prepare-commit-msg"
    else
        echo "⏭️  prepare-commit-msg hook already exists"
    fi

    # 6. Create .gitignore entries
    echo "📝 Updating .gitignore..."
    if ! grep -q ".claude/plans/" .gitignore 2>/dev/null; then
        cat >> .gitignore << 'EOF'

# Claude dotfiles
.claude/plans/*.md
!.claude/plans/.gitkeep
EOF
        echo "✅ Updated .gitignore"
    else
        echo "⏭️  .gitignore already configured"
    fi
fi

# Create .gitkeep for plans directory
touch "$CLAUDE_DIR/plans/.gitkeep"

# 7. Create context file template
if [ ! -f "$CLAUDE_DIR/context.yaml" ]; then
    cat > "$CLAUDE_DIR/context.yaml" << 'EOF'
# Repository context for Claude
# This file helps Claude understand your project

project:
  name: ""
  description: ""

languages:
  - go
  - python

frameworks:
  - kubernetes

conventions:
  commit_style: conventional

  # Add project-specific scopes for commits
  commit_scopes:
    - api
    - auth
    - db
    - k8s
    - ci

  # Add any project-specific patterns or guidelines
  guidelines: |
    Add guidelines here
EOF
    echo "✅ Created context.yaml template"
else
    echo "⏭️  context.yaml already exists"
fi

# 8. Summary
echo ""
echo "✨ Installation complete!"
echo ""

if [ "$GLOBAL_INSTALL" = true ]; then
    echo "📚 Global installation completed to: $CLAUDE_DIR"
    echo ""
    echo "Your slash commands are now available globally:"
    echo "   - /plan - Create implementation plans"
    echo "   - /review-code - Review staged changes"
    echo "   - /review-plan - Review implementation plans"
    echo "   - /commit - Generate commit messages"
    echo "   - /just-help - Get help with Just recipes"
    echo ""
    echo "To use these in a specific repo, run the local install:"
    echo "   cd /path/to/your/repo"
    echo "   $0"
    echo ""
else
    echo "📚 Next steps:"
    echo ""
    echo "1. Edit justfile to implement linting and testing:"
    echo "   - Uncomment and customize the lint recipe"
    echo "   - Uncomment and customize the test recipe"
    echo "   - See examples/justfiles/ for language-specific recipe ideas"
    echo ""
    echo "2. Slash commands are now available:"
    echo "   - /plan - Create implementation plans"
    echo "   - /review-code - Review staged changes"
    echo "   - /review-plan - Review implementation plans"
    echo "   - /commit - Generate commit messages"
    echo "   - /just-help - Get help with Just recipes"
    echo ""
    echo "3. Plan worktree recipes are available:"
    echo "   just plan-list <plan-file>      # List stages in a plan"
    echo "   just plan-setup <plan-file>     # Create worktrees for all stages"
    echo "   just plan-status <plan-file>    # Show plan status"
    echo "   just plan-validate <plan-file>  # Validate plan metadata"
    echo ""
    echo "4. Edit context file:"
    echo "   - Update .claude/context.yaml with your project details"
    echo ""
    echo "5. Test the setup:"
    echo "   just --list          # See available recipes"
    echo "   just validate        # Test validation (will fail until lint/test implemented)"
    echo "   /plan <feature>      # Try a slash command"
    echo ""
    echo "6. Enable auto-commit messages (optional):"
    echo "   chmod +x .git/hooks/prepare-commit-msg"
    echo ""
fi
