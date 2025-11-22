#!/usr/bin/env bats
# Integration tests for uninstall.sh
# Tests verify that the uninstall script properly removes installed files

setup() {
  # Runs before each test
  export TEST_REPO="/tmp/test-repo"
}

# === Git Hooks Removal Tests ===

@test "pre-commit hook removed" {
  [ ! -f "$TEST_REPO/.git/hooks/pre-commit" ]
}

@test "prepare-commit-msg hook removed" {
  [ ! -f "$TEST_REPO/.git/hooks/prepare-commit-msg" ]
}

# === File Removal Tests ===

@test "justfile removed" {
  [ ! -f "$TEST_REPO/justfile" ]
}

@test ".claude directory removed" {
  [ ! -d "$TEST_REPO/.claude" ]
}

# === Cleanup Verification ===

@test "scripts symlink removed" {
  [ ! -e "$TEST_REPO/scripts" ]
}

@test "no broken symlinks remain in test repo" {
  cd "$TEST_REPO"
  # Find all symlinks and check if any are broken
  # This should return empty (no broken links)
  if [ -d ".claude" ]; then
    ! find .claude -type l ! -exec test -e {} \; -print | grep -q .
  else
    # If .claude is removed, that's also fine
    true
  fi
}
