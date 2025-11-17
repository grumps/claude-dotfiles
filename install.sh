#!/usr/bin/env bash
set -e

DOTFILES_DIR="${HOME}/.claude-dotfiles"
CLAUDE_DIR=".claude"

echo "🚀 Installing Claude dotfiles integration..."
echo ""

# Check if we're in a git repo
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Run this from your repo root."
    exit 1
fi

# Check if claude-dotfiles exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ Claude dotfiles not found at $DOTFILES_DIR"
    echo ""
    echo "Clone first:"
    echo "  git clone https://github.com/YOUR_USERNAME/claude-dotfiles ~/.claude-dotfiles"
    exit 1
fi

# 1. Create justfile if it doesn't exist
if [ ! -f "justfile" ]; then
    echo "📝 Creating justfile..."
    cat > justfile << 'EOF'
# Import base protocol from claude-dotfiles
import? '~/.claude-dotfiles/justfiles/_base.just'

# === Required Recipes ===
# The imported _base.just defines `validate: lint test`
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

# 2. Create .claude directory structure
echo "📁 Creating .claude directory..."
mkdir -p "$CLAUDE_DIR"/{commands,prompts,plans}

# 3. Copy slash commands
echo "⚡ Copying slash commands..."
for command in "$DOTFILES_DIR/commands"/*.md; do
    filename=$(basename "$command")
    if [ ! -f "$CLAUDE_DIR/commands/$filename" ]; then
        cp "$command" "$CLAUDE_DIR/commands/"
        echo "✅ Copied $filename"
    else
        echo "⏭️  $filename already exists"
    fi
done

# 4. Copy prompt templates
echo "📋 Copying prompt templates..."
for template in "$DOTFILES_DIR/prompts"/*.md; do
    filename=$(basename "$template")
    if [ ! -f "$CLAUDE_DIR/prompts/$filename" ]; then
        cp "$template" "$CLAUDE_DIR/prompts/"
        echo "✅ Copied $filename"
    else
        echo "⏭️  $filename already exists"
    fi
done

# 5. Set up git hooks
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
echo "3. Edit context file:"
echo "   - Update .claude/context.yaml with your project details"
echo ""
echo "4. Test the setup:"
echo "   just --list          # See available recipes"
echo "   just validate        # Test validation (will fail until lint/test implemented)"
echo "   /plan <feature>      # Try a slash command"
echo ""
echo "5. Enable auto-commit messages (optional):"
echo "   chmod +x .git/hooks/prepare-commit-msg"
echo ""
