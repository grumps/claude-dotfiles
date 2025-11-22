# Integration Tests

This directory contains BATS (Bash Automated Testing System) integration tests for the claude-dotfiles installation and uninstallation scripts.

## Test Files

### test-install.bats (22 test cases)
Tests the `install.sh` script functionality:
- **Justfile Tests** (3 tests)
  - Justfile creation
  - Base recipe imports
  - Plan recipe imports
- **Claude Directory Structure** (5 tests)
  - Directory creation (.claude, commands, prompts, plans)
  - .gitkeep file creation
- **Symlink Tests** (5 tests)
  - Scripts directory symlink
  - Slash commands symlinks
  - Prompt templates symlinks
- **Git Hooks Tests** (4 tests)
  - Pre-commit hook installation and permissions
  - Prepare-commit-msg hook (disabled by default)
- **Configuration Files** (3 tests)
  - context.yaml creation and structure
  - .gitignore updates
- **Just Recipe Availability** (2 tests)
  - Base recipes available
  - Plan recipes available

### test-uninstall.bats (6 test cases)
Tests the `uninstall.sh` script functionality:
- Git hooks removal (2 tests)
- File removal (2 tests)
- Cleanup verification (2 tests)

## Running Tests Locally

### Using Just (Recommended)
```bash
# Run integration tests in Docker container
just test-install
```

This will:
1. Start an Arch Linux container
2. Install dependencies (git, bats, just)
3. Create a test repository
4. Run install.sh
5. Execute BATS test suite
6. Run uninstall.sh
7. Verify cleanup

### Manual Testing with Docker
```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace archlinux:latest /bin/bash -c '
  pacman -Sy --noconfirm git bats just base-devel
  mkdir -p /tmp/test-repo
  cd /tmp/test-repo
  git init
  git config user.name "Test User"
  git config user.email "test@example.com"
  bash /workspace/install.sh
  bats /workspace/tests/integration/test-install.bats
'
```

### Manual Testing with Podman
Replace `docker` with `podman` in the above command.

## CI/CD Integration

These tests are automatically run in GitHub Actions via `.github/workflows/integration-tests.yml`:

- **Trigger**: On PR changes to install.sh, uninstall.sh, scripts/, hooks/, justfiles/, tests/
- **Environment**: Arch Linux container (archlinux:latest)
- **Jobs**:
  - `test-install`: Runs installation and uninstallation tests
  - `test-plan-worktree`: Tests plan worktree script functionality

## Test Coverage

### Covered Scenarios
✅ Fresh installation in clean repository
✅ Justfile creation and imports
✅ Directory structure creation
✅ Symlink creation and validation
✅ Git hooks installation
✅ Configuration file creation
✅ Recipe availability
✅ Complete uninstallation
✅ Cleanup verification

### Not Yet Covered (Future Work)
- Global installation mode (`install.sh --global`)
- Notification hooks installation
- Edge cases: Existing justfile, partial installations
- Multiple install/uninstall cycles
- Plan worktree script comprehensive testing

## Writing New Tests

BATS test syntax:
```bash
@test "test description" {
  # Test code here
  [ -f /path/to/file ]  # Check file exists
  grep -q "pattern" file  # Check file contains pattern
  [ -L /path/to/symlink ]  # Check symlink exists
}
```

Each test should:
1. Be independent (can run in any order)
2. Test one specific behavior
3. Have a clear, descriptive name
4. Use the `$TEST_REPO` variable for the test repository path

## Dependencies

- **bats-core**: Bash testing framework
- **git**: Version control (for test repository creation)
- **just**: Task runner (for running justfiles)
- **Docker/Podman**: Container runtime (for isolated testing)

## References

- BATS Documentation: https://github.com/bats-core/bats-core
- GitHub Actions Integration: `.github/workflows/integration-tests.yml`
- Just Recipe: `justfiles/ci.just` (test-install recipe)
