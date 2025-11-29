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
  echo "🌍 Installing Claude dotfiles globally..."
else
  CLAUDE_DIR=".claude"
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
    cat >justfile <<EOF
# Import base protocol from claude-dotfiles
import? '$DOTFILES_DIR/justfiles/_base.just'

# Import plan worktree management recipes (optional)
import? '$DOTFILES_DIR/justfiles/plans.just'

# === Required Recipes ===
# The imported _base.just defines \`validate: lint test\`
# You MUST implement lint and test, or validation will fail
# You SHOULD implement fmt for auto-formatting (runs in hooks)

# Placeholder fmt recipe - customize for your project
fmt:
  @echo "⚠️  No formatters configured yet"
  @echo "   Add formatting commands for your project (gofmt, ruff format, etc.)"
  @echo "✅ Formatting complete (no formatters configured)"

# Placeholder lint recipe - customize for your project
lint:
  @echo "⚠️  No linters configured yet"
  @echo "   Add linting commands for your project (shellcheck, ruff, yamllint, etc.)"
  @echo "✅ Lint check passed (no linters configured)"

# Placeholder test recipe - customize for your project
test:
  @echo "⚠️  No tests configured yet"
  @echo "   Add test commands for your project (go test, pytest, etc.)"
  @echo "✅ Tests passed (no tests configured)"

# === Custom Recipes ===

# Add your repository-specific recipes below

# Example recipes (uncomment and customize):
# fmt:
#   gofmt -w .
#   ruff format .
#
# lint:
#   golangci-lint run ./...
#   ruff check .
#   yamllint .
#
# test:
#   go test -race -cover ./...
#   pytest -v
EOF
    echo "✅ Created justfile"
  else
    echo "⏭️  justfile already exists, skipping"
  fi
fi

# 2. Create .claude directory structure
echo "📁 Creating Claude directory..."
mkdir -p "$CLAUDE_DIR"/{commands,prompts,skills,plans}

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

# 4a. Symlink skills
echo "🧠 Symlinking skills..."
for skill_dir in "$DOTFILES_DIR/skills"/*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_DIR/skills/$skill_name"
    if [ ! -e "$target" ]; then
      ln -s "$skill_dir" "$target"
      echo "✅ Linked $skill_name"
    else
      echo "⏭️  $skill_name already exists"
    fi
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
    # Explicitly remove execute permission - user can enable later
    chmod -x .git/hooks/prepare-commit-msg 2>/dev/null || chmod 644 .git/hooks/prepare-commit-msg
    echo "✅ Copied prepare-commit-msg hook (disabled by default)"
    echo "   Enable with: chmod +x .git/hooks/prepare-commit-msg"
  else
    echo "⏭️  prepare-commit-msg hook already exists"
  fi

  # 6. Create .gitignore entries
  echo "📝 Updating .gitignore..."
  if ! grep -q ".claude/plans/" .gitignore 2>/dev/null; then
    cat >>.gitignore <<'EOF'

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

# 7. Create/update settings.json with hooks configuration
if [ "$GLOBAL_INSTALL" = true ]; then
  # Global install: Update ~/.claude/settings.json
  GLOBAL_SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

  # Create empty settings if it doesn't exist
  if [ ! -f "$GLOBAL_SETTINGS_FILE" ]; then
    echo '{}' >"$GLOBAL_SETTINGS_FILE"
  fi

  # Check if jq is available
  if command -v jq &>/dev/null; then
    # Backup existing settings
    BACKUP_FILE="${GLOBAL_SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$GLOBAL_SETTINGS_FILE" "$BACKUP_FILE"
    echo "✅ Backed up global settings to: $BACKUP_FILE"

    # Create hook configuration
    HOOK_CONFIG=$(jq -n '{
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [
              {
                "type": "command",
                "command": "just fmt lint test",
                "timeout": 120
              }
            ]
          }
        ]
      }
    }')

    # Merge with existing settings (deep merge for hooks)
    # Strategy: upsert PostToolUse hook by matcher, preserve all other hooks
    # Example: If existing has PostToolUse[Bash, Edit|Write] and new has PostToolUse[Edit|Write],
    # result will be PostToolUse[Bash, Edit|Write(updated)]
    TMP_FILE="${GLOBAL_SETTINGS_FILE}.tmp"
    if ! jq -s '
      .[0] as $existing |
      .[1] as $new |
      # Merge top-level settings
      $existing * $new |
      # Deep merge hooks
      .hooks = (
        ($existing.hooks // {}) as $eh |
        ($new.hooks // {}) as $nh |
        # Process each hook type
        $eh |
        to_entries |
        map(
          .key as $hook_type |
          if ($nh | has($hook_type)) then
            # Hook type exists in new config - merge arrays by matcher
            .value = (
              .value as $existing_hooks |
              $nh[$hook_type] as $new_hooks |
              # Get matchers from new hooks
              ($new_hooks | map(.matcher)) as $new_matchers |
              # Keep existing hooks that dont match new matchers, then add all new hooks
              ($existing_hooks | map(select(.matcher as $m | $new_matchers | index($m) | not))) + $new_hooks
            )
          else
            # Hook type not in new config - keep as is
            .
          end
        ) |
        from_entries |
        # Add hook types that only exist in new config
        . + (
          $nh |
          to_entries |
          map(select(.key as $k | $eh | has($k) | not)) |
          from_entries
        )
      )
    ' "$GLOBAL_SETTINGS_FILE" <(echo "$HOOK_CONFIG") >"$TMP_FILE"; then
      echo "❌ Failed to merge settings with hooks configuration"
      echo "   Your settings file may have invalid JSON syntax: $GLOBAL_SETTINGS_FILE"
      echo "   A backup was created at: $BACKUP_FILE"
      echo "   You can restore it with: cp \"$BACKUP_FILE\" \"$GLOBAL_SETTINGS_FILE\""
      exit 1
    fi
    mv "$TMP_FILE" "$GLOBAL_SETTINGS_FILE"

    echo "✅ Updated global settings with hooks"
    echo "   - Hooks will run 'just fmt lint test' after Edit/Write operations"
    echo "   - Settings file: $GLOBAL_SETTINGS_FILE"
  else
    echo "⚠️  jq not found - skipping global hooks configuration"
    echo "   Install jq and re-run to configure hooks automatically"
  fi
else
  # Local install: Create .claude/settings.json
  if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    cat >"$CLAUDE_DIR/settings.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && just fmt lint test",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
EOF
    echo "✅ Created settings.json with hooks"
    echo "   - Hooks will run 'just fmt lint test' after Edit/Write operations"
    echo "   - Customize timeout or disable hooks by editing .claude/settings.json"
  else
    echo "⏭️  settings.json already exists"
  fi
fi

# 8. Create context file template
if [ ! -f "$CLAUDE_DIR/context.yaml" ]; then
  cat >"$CLAUDE_DIR/context.yaml" <<'EOF'
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

# 9. Optional: Notification hooks setup (Linux only, interactive mode only)
if [ "$(uname)" = "Linux" ] && [ -t 0 ] && [ -z "${CI:-}" ]; then
  echo ""
  read -p "🔔 Would you like to set up desktop notifications for Claude? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$DOTFILES_DIR/scripts/install-notification-hooks.sh" ]; then
      echo ""
      "$DOTFILES_DIR/scripts/install-notification-hooks.sh"
    else
      echo "❌ Notification hooks script not found"
    fi
  else
    echo "⏭️  Skipping notification setup"
    echo "   You can set it up later by running:"
    echo "   $DOTFILES_DIR/scripts/install-notification-hooks.sh"
  fi
elif [ "$(uname)" = "Linux" ]; then
  # Non-interactive mode (CI/automation) - skip prompt, just inform
  echo "⏭️  Skipping notification setup (non-interactive mode)"
  echo "   You can set it up later by running:"
  echo "   $DOTFILES_DIR/scripts/install-notification-hooks.sh"
fi

# 9b. Note about hooks configuration
echo ""
echo "📝 Note about Claude Code hooks:"
if [ "$GLOBAL_INSTALL" = true ]; then
  echo "   Global hooks are configured in: ~/.claude/settings.json"
  echo "   Use the notification install script above for additional hooks"
else
  echo "   Project hooks are configured in: .claude/settings.json"
  echo "   These will automatically run 'just fmt lint test' after code changes"
fi
echo ""

# 10. Summary
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
  echo "1. Edit justfile to implement formatting, linting, and testing:"
  echo "   - Uncomment and customize the fmt recipe"
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
  echo "5. Review Claude Code hooks:"
  echo "   - Hooks are configured in .claude/settings.json"
  echo "   - Currently runs 'just fmt lint test' after Edit/Write"
  echo "   - Adjust timeout or disable if needed"
  echo ""
  echo "6. Test the setup:"
  echo "   just --list          # See available recipes"
  echo "   just validate        # Test validation (will fail until lint/test implemented)"
  echo "   /plan <feature>      # Try a slash command"
  echo ""
  echo "7. Enable auto-commit messages (optional):"
  echo "   chmod +x .git/hooks/prepare-commit-msg"
  echo ""
  if [ "$(uname)" = "Linux" ]; then
    echo "8. Set up desktop notifications (optional):"
    echo "   $DOTFILES_DIR/scripts/install-notification-hooks.sh"
    echo ""
  fi
fi
