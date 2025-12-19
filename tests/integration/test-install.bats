#!/usr/bin/env bats
# Integration tests for install.sh
# Tests verify that the installation script creates all expected files and symlinks

setup() {
  # Runs before each test
  export TEST_REPO="/tmp/test-repo"
}

# === Justfile Tests ===

@test "justfile created in test repo" {
  [ -f "$TEST_REPO/justfile" ]
}

@test "justfile imports base recipes" {
  grep -q "_base.just" "$TEST_REPO/justfile"
}

@test "justfile imports plan recipes" {
  grep -q "plans.just" "$TEST_REPO/justfile"
}

# === Claude Directory Structure Tests ===

@test ".claude directory created" {
  [ -d "$TEST_REPO/.claude" ]
}

@test ".claude/plugins directory created" {
  [ -d "$TEST_REPO/.claude/plugins" ]
}

@test ".claude/prompts directory created" {
  [ -d "$TEST_REPO/.claude/prompts" ]
}

@test ".claude/plans directory created" {
  [ -d "$TEST_REPO/.claude/plans" ]
}

@test ".claude/plans/.gitkeep created" {
  [ -f "$TEST_REPO/.claude/plans/.gitkeep" ]
}

# === Symlink Tests ===

@test "scripts directory symlinked" {
  [ -L "$TEST_REPO/scripts" ]
}

@test "scripts symlink points to dotfiles scripts" {
  # Check that symlink points to a scripts directory (path varies by environment)
  local link_target
  link_target=$(readlink "$TEST_REPO/scripts")
  [[ "$link_target" == */scripts ]]
}

@test "gdf plugin symlinked" {
  [ -L "$TEST_REPO/.claude/plugins/gdf" ]
  [ -f "$TEST_REPO/.claude/plugins/gdf/plugin.json" ]
  [ -f "$TEST_REPO/.claude/plugins/gdf/commands/planning/pln.md" ]
  [ -f "$TEST_REPO/.claude/plugins/gdf/commands/git/commit.md" ]
  [ -f "$TEST_REPO/.claude/plugins/gdf/commands/review/rvc.md" ]
}

@test "prompt templates symlinked" {
  [ -L "$TEST_REPO/.claude/prompts/plan.md" ]
  [ -L "$TEST_REPO/.claude/prompts/commit.md" ]
  [ -L "$TEST_REPO/.claude/prompts/review-code.md" ]
}

# === Git Hooks Tests ===

@test "pre-commit hook installed" {
  [ -f "$TEST_REPO/.git/hooks/pre-commit" ]
}

@test "pre-commit hook is a symlink" {
  [ -L "$TEST_REPO/.git/hooks/pre-commit" ]
}

@test "pre-commit hook is executable" {
  [ -x "$TEST_REPO/.git/hooks/pre-commit" ]
}

@test "prepare-commit-msg hook copied (not executable)" {
  [ -f "$TEST_REPO/.git/hooks/prepare-commit-msg" ]
  [ ! -x "$TEST_REPO/.git/hooks/prepare-commit-msg" ]
}

# === Configuration Files Tests ===

@test "context.yaml created" {
  [ -f "$TEST_REPO/.claude/context.yaml" ]
}

@test "context.yaml contains project section" {
  grep -q "project:" "$TEST_REPO/.claude/context.yaml"
}

@test "context.yaml contains languages section" {
  grep -q "languages:" "$TEST_REPO/.claude/context.yaml"
}

@test ".gitignore updated with Claude entries" {
  [ -f "$TEST_REPO/.gitignore" ]
  grep -q ".claude/plans/\*\.md" "$TEST_REPO/.gitignore"
}

# === Just Recipe Availability Tests ===

@test "just --list shows base recipes" {
  cd "$TEST_REPO"
  just --list | grep -q "validate"
}

@test "just --list shows plan recipes" {
  cd "$TEST_REPO"
  just --list | grep -q "plan-list"
}
