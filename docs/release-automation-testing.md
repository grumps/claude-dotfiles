# Release Automation - Local Testing Guide

This guide explains how to test the release automation workflow locally without needing to push to GitHub Actions.

## Overview

The release automation is built using:

- **git-cliff** (Rust): Changelog generation
- **Just**: Task runner for local-CI parity
- **gh CLI**: GitHub release creation

All release logic lives in `justfiles/ci.just`, making it fully testable locally.

## Quick Start: Using Docker (Recommended)

The easiest way to test locally is using the pre-built Docker container with all tools included:

```bash
# Pull the container with all tools pre-installed (including git-cliff)
docker pull ghcr.io/grumps/claude-dotfiles:master

# Test release notes generation
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:master \
  just release-notes v1.0.0

# Test changelog generation
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:master \
  just changelog

# Interactive shell to run multiple commands
docker run -it --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:master
# Inside container:
# just release-notes v1.0.0
# just changelog
```

This container includes:

- ✅ Just (task runner)
- ✅ git-cliff (changelog generator)
- ✅ All validation tools (shellcheck, shfmt, ruff, etc.)
- ✅ Same environment as GitHub Actions

**Note**: The container does not include `gh` CLI. For testing `github-release` recipe, you'll need to install it manually or use native installation (see below).

## Prerequisites (Native Installation)

If you prefer to install tools directly on your machine instead of using Docker:

```bash
# Install Just (if not already installed)
# Arch Linux
sudo pacman -S just

# macOS
brew install just

# Other platforms: https://github.com/casey/just#installation

# Install git-cliff (Rust-based changelog generator)
# Download latest release
curl -L https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv git-cliff-*/git-cliff /usr/local/bin/
chmod +x /usr/local/bin/git-cliff

# Verify installation
git-cliff --version

# Install GitHub CLI (optional, only needed for github-release recipe)
# Arch Linux
sudo pacman -S github-cli

# macOS
brew install gh

# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Authenticate with GitHub (for github-release recipe)
gh auth login
```

## Local Testing Workflows

### 1. Test Changelog Generation

Generate the CHANGELOG.md file from git history:

```bash
# Generate full changelog
just changelog

# Review the generated CHANGELOG.md
cat CHANGELOG.md
```

**Expected Output:**

- CHANGELOG.md file updated with all conventional commits
- Commits grouped by type: Added, Fixed, Documentation, etc.
- Follows Keep a Changelog format

**Validation:**

- Check that all conventional commits are included
- Verify grouping is correct (feat → Added, fix → Fixed, etc.)
- Ensure version tags are properly formatted

### 2. Test Release Notes Generation (Argo-Compatible)

This recipe has **no GitHub dependency** and works in any CI environment:

```bash
# Test with a valid semantic version tag
just release-notes v1.0.0

# Test with invalid tag format (should fail)
just release-notes 1.0.0          # ❌ Missing 'v' prefix
just release-notes v1.0           # ❌ Not semver format
just release-notes feature-branch # ❌ Not a version tag
```

**Expected Output:**

- Valid tag: Release notes for that version printed to stdout
- Invalid tag: Error message explaining expected format

**Validation:**

- Verify tag format validation works (must be `v1.2.3`)
- Check that release notes only include relevant commits
- Ensure output is clean (no progress bars or extra output)

### 3. Test GitHub Release Creation (Local)

**Prerequisites:**

- Must have `gh` CLI installed and authenticated
- Must be in a repository with a remote on GitHub
- Must have push access to create tags and releases

#### Option A: Test with a test tag on your fork

```bash
# Create a test tag locally
git tag v0.0.1-test
git push origin v0.0.1-test

# Test the github-release recipe
just github-release v0.0.1-test

# Verify release created on GitHub
gh release list

# Clean up test release
gh release delete v0.0.1-test --yes
git tag -d v0.0.1-test
git push origin :refs/tags/v0.0.1-test
```

#### Option B: Dry-run validation (no actual release)

You can test the recipe logic without creating a release:

```bash
# Test tag validation
just release-notes v0.0.1-test > /dev/null
echo "Tag validation: $?"  # Should be 0 for success

# Generate release notes to see what would be included
just release-notes v0.0.1-test

# Manually inspect what files would be attached
ls -lh install.sh uninstall.sh
```

### 4. Test Full Release Workflow

This combines all steps:

```bash
# Create a test tag locally (don't push yet)
git tag v0.0.2-test

# Run full release workflow locally
just release v0.0.2-test

# This will:
# 1. Validate tag format
# 2. Generate release notes
# 3. Create GitHub release (if gh CLI is authenticated)

# Clean up
gh release delete v0.0.2-test --yes
git tag -d v0.0.2-test
```

## Testing Scenarios

### Scenario 1: Validate Tag Format Checking

```bash
# Test various invalid tag formats
for tag in "1.0.0" "v1.0" "vX.Y.Z" "release-1.0.0"; do
  echo "Testing tag: $tag"
  just release-notes "$tag" 2>&1 | grep -q "Invalid tag format" && echo "✅ Correctly rejected" || echo "❌ Should have rejected"
done

# Test valid formats
for tag in "v1.0.0" "v0.1.0" "v10.20.30"; do
  echo "Testing tag: $tag"
  just release-notes "$tag" > /dev/null 2>&1 && echo "✅ Correctly accepted" || echo "❌ Should have accepted"
done
```

### Scenario 2: Validate Conventional Commit Parsing

```bash
# Create test commits with different types
git commit --allow-empty -m "feat: add new feature"
git commit --allow-empty -m "fix: correct bug"
git commit --allow-empty -m "docs: update readme"
git commit --allow-empty -m "chore: update dependencies"

# Generate changelog and verify grouping
just changelog

# Check that commits are in correct sections
grep -A 5 "### Added" CHANGELOG.md | grep "add new feature"
grep -A 5 "### Fixed" CHANGELOG.md | grep "correct bug"
grep -A 5 "### Documentation" CHANGELOG.md | grep "update readme"

# Clean up test commits
git reset --hard HEAD~4
```

### Scenario 3: Test Without GitHub Dependency (Argo-Compatible)

This validates that `release-notes` works in restricted environments:

```bash
# Simulate restricted environment (no network, no GitHub CLI)
docker run --rm -v "$(pwd):/workspace" -w /workspace archlinux:latest bash -c '
  pacman -Sy --noconfirm git just
  curl -L https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-x86_64-unknown-linux-musl.tar.gz | tar xz
  mv git-cliff-*/git-cliff /usr/local/bin/
  just release-notes v1.0.0
'
```

**Expected:**

- Should generate release notes successfully
- No GitHub API calls needed
- Works in air-gapped environments

## Troubleshooting

### Issue: git-cliff not found

```bash
# Verify git-cliff is installed
which git-cliff
git-cliff --version

# If not found, reinstall
curl -L https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv git-cliff-*/git-cliff /usr/local/bin/
```

### Issue: gh CLI not authenticated

```bash
# Check authentication status
gh auth status

# Login if needed
gh auth login

# Use a personal access token if interactive login doesn't work
gh auth login --with-token < token.txt
```

### Issue: Permission denied when creating release

```bash
# Verify you have write access to the repository
gh repo view

# Check if you're authenticated as the correct user
gh auth status

# Verify the tag exists
git tag -l | grep v1.0.0
```

### Issue: Release notes are empty

```bash
# Check if there are any conventional commits
git log --oneline --grep="^feat\|^fix\|^docs"

# Verify cliff.toml configuration
cat cliff.toml

# Test with verbose output
git-cliff --config cliff.toml --unreleased --tag v1.0.0 -v
```

## CI/CD Integration

### GitHub Actions

The `.github/workflows/release.yml` workflow automatically:

1. Triggers on version tags (`v*.*.*`)
2. Installs Just and git-cliff
3. Runs `just github-release $TAG`
4. Creates GitHub release with changelog

### Argo Workflows (Future)

The `release-notes` recipe is Argo-compatible:

- No GitHub-specific dependencies
- Works in any container with git and git-cliff
- Output to stdout (can be captured by workflow)

Example Argo workflow:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
spec:
  entrypoint: release
  templates:
  - name: release
    container:
      image: myorg/ci-tools:latest
      command: [just, release-notes, "{{workflow.parameters.tag}}"]
```

## Best Practices

1. **Always test locally before pushing tags**

   ```bash
   just release-notes v1.0.0  # Verify notes look good
   git tag v1.0.0             # Create tag
   git push origin v1.0.0     # Trigger workflow
   ```

2. **Use conventional commits**
   - `feat:` for new features → Added section
   - `fix:` for bug fixes → Fixed section
   - `docs:` for documentation → Documentation section

3. **Validate tag format**
   - Must be `v<major>.<minor>.<patch>`
   - Examples: `v1.0.0`, `v2.1.3`, `v10.20.30`
   - NOT: `1.0.0`, `v1.0`, `release-1.0.0`

4. **Test in isolation**

   ```bash
   # Create a test branch
   git checkout -b test-release

   # Make test commits
   git commit --allow-empty -m "feat: test feature"

   # Test release notes
   just release-notes v0.0.1-test

   # Clean up
   git checkout main
   git branch -D test-release
   ```

5. **Review before creating release**

   ```bash
   # Generate notes to review
   just release-notes v1.0.0 > release-notes.txt

   # Review the content
   cat release-notes.txt

   # If satisfied, create release
   just github-release v1.0.0
   ```

## Recipe Reference

### `just changelog`

- **Purpose**: Generate/update full CHANGELOG.md
- **Dependencies**: git-cliff
- **GitHub Required**: No
- **Output**: CHANGELOG.md file

### `just release-notes <tag>`

- **Purpose**: Generate release notes for specific version
- **Dependencies**: git-cliff
- **GitHub Required**: No (Argo-compatible)
- **Output**: Release notes to stdout
- **Validates**: Semantic version tag format

### `just github-release <tag>`

- **Purpose**: Create GitHub release with notes and assets
- **Dependencies**: git-cliff, gh CLI
- **GitHub Required**: Yes (uses GitHub API)
- **Output**: GitHub release with install.sh and uninstall.sh
- **Validates**: Tag format, creates release notes

### `just release <tag>`

- **Purpose**: Full release workflow (notes + GitHub release)
- **Dependencies**: git-cliff, gh CLI
- **GitHub Required**: Yes (for final release creation)
- **Output**: Release notes + GitHub release

## Example: Complete Local Test

```bash
# 1. Install tools (if needed)
which git-cliff || echo "Install git-cliff first"
which gh || echo "Install gh CLI first"

# 2. Test changelog generation
just changelog
git diff CHANGELOG.md  # Review changes

# 3. Test release notes with a test tag
just release-notes v0.0.1-test

# 4. If you want to test actual release creation (optional)
git tag v0.0.1-test
just github-release v0.0.1-test

# 5. Verify release on GitHub
gh release view v0.0.1-test

# 6. Clean up
gh release delete v0.0.1-test --yes
git tag -d v0.0.1-test

# 7. All tests passed!
echo "✅ Release automation validated locally"
```

## Summary

Key advantages of this approach:

- ✅ All recipes testable locally with Just
- ✅ No GitHub Actions needed for testing
- ✅ `release-notes` has zero GitHub dependencies (Argo-compatible)
- ✅ Clear validation of tag format
- ✅ git-cliff generates consistent changelog format
- ✅ Can test full workflow before pushing to CI

This ensures **local-CI parity**: the same commands run locally and in GitHub Actions.
