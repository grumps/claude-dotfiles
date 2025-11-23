#!/usr/bin/env bash
set -e

CLAUDE_DIR=".claude"

# Parse arguments
FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
  FORCE=true
fi

echo "🗑️  Uninstalling Claude dotfiles integration..."
echo ""

# Check if we're in a git repo
if [ ! -d ".git" ]; then
  echo "❌ Not in a git repository."
  exit 1
fi

# Remove git hooks
echo "🪝 Removing git hooks..."
if [ -L ".git/hooks/pre-commit" ]; then
  rm .git/hooks/pre-commit
  echo "✅ Removed pre-commit hook"
fi

if [ -f ".git/hooks/prepare-commit-msg" ]; then
  rm .git/hooks/prepare-commit-msg
  echo "✅ Removed prepare-commit-msg hook"
fi

# Remove symlinks
echo "🔗 Removing symlinks..."
if [ -L "$CLAUDE_DIR/skills/shared" ]; then
  rm "$CLAUDE_DIR/skills/shared"
  echo "✅ Removed skills symlink"
fi

if [ -L "scripts" ]; then
  rm scripts
  echo "✅ Removed scripts symlink"
fi

# Ask before removing justfile (or auto-remove with --force)
if [ -f "justfile" ]; then
  if [ "$FORCE" = true ]; then
    rm justfile
    echo "✅ Removed justfile"
  else
    echo ""
    read -p "Remove justfile? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm justfile
      echo "✅ Removed justfile"
    else
      echo "⏭️  Kept justfile"
    fi
  fi
fi

# Ask before removing .claude directory (or auto-remove with --force)
if [ -d "$CLAUDE_DIR" ]; then
  if [ "$FORCE" = true ]; then
    rm -rf "$CLAUDE_DIR"
    echo "✅ Removed .claude directory"
  else
    echo ""
    read -p "Remove .claude directory? This will delete plans and customized prompts (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "$CLAUDE_DIR"
      echo "✅ Removed .claude directory"
    else
      echo "⏭️  Kept .claude directory"
    fi
  fi
fi

echo ""
echo "✨ Uninstall complete!"
