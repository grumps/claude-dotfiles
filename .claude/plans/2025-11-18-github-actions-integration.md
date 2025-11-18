# Implementation Plan: GitHub Actions CI/CD Integration

<!--
This template uses JSON metadata to define extractable implementation stages.
Each stage can be developed in its own git worktree for parallel development.

To set up worktrees: just plan-setup .claude/plans/2025-11-18-github-actions-integration.md
See skills/plan-worktree/SKILL.md for details.
-->

```json metadata
{
  "plan_id": "2025-11-18-github-actions-ci",
  "created": "2025-11-18",
  "author": "Claude Code",
  "status": "draft",
  "stages": [
    {
      "id": "shell-validation",
      "name": "Shell Script Validation Workflow",
      "branch": "feature/gh-actions-shell-validation",
      "worktree_path": "../worktrees/gh-actions-ci/shell-validation",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "python-validation",
      "name": "Python Linting and Type Checking",
      "branch": "feature/gh-actions-python-validation",
      "worktree_path": "../worktrees/gh-actions-ci/python-validation",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "markdown-validation",
      "name": "Markdown Linting and Link Checking",
      "branch": "feature/gh-actions-markdown-validation",
      "worktree_path": "../worktrees/gh-actions-ci/markdown-validation",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "integration-testing",
      "name": "Installation and Integration Testing",
      "branch": "feature/gh-actions-integration-tests",
      "worktree_path": "../worktrees/gh-actions-ci/integration-testing",
      "status": "not-started",
      "depends_on": ["shell-validation", "python-validation"]
    },
    {
      "id": "pr-validation",
      "name": "Pull Request Validation Workflow",
      "branch": "feature/gh-actions-pr-validation",
      "worktree_path": "../worktrees/gh-actions-ci/pr-validation",
      "status": "not-started",
      "depends_on": ["shell-validation", "python-validation", "markdown-validation", "integration-testing"]
    },
    {
      "id": "release-automation",
      "name": "Release and Changelog Automation",
      "branch": "feature/gh-actions-release-automation",
      "worktree_path": "../worktrees/gh-actions-ci/release-automation",
      "status": "not-started",
      "depends_on": []
    }
  ]
}
```

## Overview

Implement comprehensive GitHub Actions CI/CD workflows that leverage Just recipes for testing, linting, validation, and releases. GitHub Actions orchestrates the workflow, while justfiles define the actual CI tasks, ensuring developers can run the same validations locally as in CI. This ensures code quality, prevents regressions, and streamlines the development process for a repository that provides development workflow infrastructure for Claude Code.

**Core Principle**: Just commands define all CI logic; GitHub Actions simply invokes `just <command>`.

## Requirements

### Functional Requirements

**Linting & Static Analysis:**
- [ ] Validate all shell scripts with ShellCheck
- [ ] Lint Python scripts with ruff following repository style guide
- [ ] Type check Python scripts with mypy
- [ ] Lint markdown files for consistency and broken links
- [ ] Validate Just recipe syntax
- [ ] Check for common security issues in shell scripts

**Testing:**
- [ ] Test install.sh in clean Arch Linux environment
- [ ] Test uninstall.sh cleanup behavior
- [ ] Validate example justfiles can be parsed
- [ ] Test plan worktree script functionality
- [ ] Verify symlink creation works correctly
- [ ] Test git hooks execute properly

**Pull Request Automation:**
- [ ] Run all validations on PRs
- [ ] Comment on PRs with validation results
- [ ] Block merge if critical checks fail
- [ ] Validate commit message format (conventional commits)
- [ ] Check for CHANGELOG.md updates on feature branches

**Release Automation:**
- [ ] Automated version tagging
- [ ] Generate release notes from CHANGELOG.md
- [ ] Create GitHub releases automatically
- [ ] Validate semantic versioning compliance

**Documentation:**
- [ ] Validate internal links
- [ ] Check external links (with caching to avoid rate limits)
- [ ] Ensure code examples in docs are valid
- [ ] (Optional/Future) Spell check with custom technical dictionary

### Non-Functional Requirements

- [ ] Performance: CI runs complete in under 5 minutes for standard PRs
- [ ] Reliability: Workflows use pinned action versions for reproducibility
- [ ] Security: Use GitHub-recommended security practices (no hardcoded secrets, minimal permissions)
- [ ] Cost: Optimize for GitHub Actions free tier usage
- [ ] Maintainability: Clear workflow structure, reusable composite actions

## Technical Approach

### Architecture

**Justfile-Centric Design:**
All CI tasks are defined as Just recipes in `justfiles/ci.just`. GitHub Actions workflows are thin wrappers that:
1. Set up the environment
2. Invoke `just <task>`
3. Report results

**Directory Structure:**
```
justfiles/
  ci.just                 # CI/CD recipes (lint-shell, lint-python, test-install, etc.)
.github/
  workflows/
    validate.yml          # Calls `just lint-shell`, `just lint-python`, `just lint-markdown`
    integration-tests.yml # Calls `just test-install`
    pr-checks.yml         # Orchestrates all PR validation
    release.yml           # Calls `just release`
```

**Data Flow:**
1. Developer can run `just lint-shell` locally (same as CI)
2. PR opened triggers `validate.yml` → runs `just lint-*` commands
3. Integration tests run `just test-install` in Arch container
4. Results aggregate and block merge if failures
5. On version tag push, `just release` validates and creates GitHub release

**Benefits:**
- Developers run the exact same commands locally as CI
- CI logic lives in justfiles (version controlled, reviewable)
- Easy to debug: `just <command>` locally reproduces CI failures
- No vendor lock-in to GitHub Actions

### Technologies

**GitHub Actions:**
- ubuntu-latest runners (for running Just commands)
- archlinux/archlinux:latest container (for install script testing)

**Linting & Validation Tools (Rust-based preferred):**
- **ShellCheck** (v0.10.0+): Shell script static analysis (Haskell, but industry standard)
- **shfmt** (v3.8.0+): Shell script formatting validation (Go, but widely used)
- **ruff** (v0.8.0+): Python linting and formatting (Rust-based, follows docs/python-style-guide.md)
- **mypy** (v1.14.0+): Python type checking
- **lychee** (Rust): Fast link checker for markdown (replaces markdown-link-check)
- **markdownlint-cli2**: Markdown linting (Node.js - tolerated for now, may replace with mdbook-lint later)
- **actionlint** (Go): Validate GitHub Actions workflow syntax

**Testing Tools:**
- **bats-core**: Bash Automated Testing System for integration tests
- **just**: Task runner and CI orchestrator
- **uv** (Rust): Python script execution (as used in scripts/planworktree.py)

**Release Tools (Rust-based):**
- **git-cliff** (Rust): Changelog generation and management
- GitHub API for release creation (via curl or gh CLI)

### Design Patterns

- **Justfile-First**: All CI logic in Just recipes, GitHub Actions only orchestrates
- **Local-CI Parity**: Developers run exact same commands locally as CI runs
- **Conditional Execution**: Skip expensive tests on documentation-only changes (path filtering)
- **Caching Strategy**: Cache tool installations and dependencies
- **Fail-Fast Disabled**: Continue running all validations even if one fails (for complete feedback)

### Existing Code to Follow

- Repository's own TESTING.md checklist informs integration test scenarios
- CONTRIBUTING.md defines code style standards to enforce
- docs/python-style-guide.md specifies Python standards (ruff configuration)
- install.sh and uninstall.sh are primary integration test targets

## Implementation Stages

### Stage 1: Shell Script Validation Workflow

**Stage ID**: `shell-validation`
**Branch**: `feature/gh-actions-shell-validation`
**Status**: Not Started
**Dependencies**: None

#### What
Create Just recipe for shell script validation (ShellCheck + shfmt) and GitHub Actions workflow that invokes it.

#### Why
Shell scripts (install.sh, uninstall.sh, hooks, helper scripts) are core to the repository. ShellCheck catches common bugs, security issues, and portability problems before they reach users. Using Just recipes allows developers to run the same checks locally.

#### How

**Architecture**:
1. Define `just lint-shell` recipe in `justfiles/ci.just`
2. GitHub Actions workflow calls `just lint-shell`
3. Developers can run `just lint-shell` locally for same validation

**Implementation Details**:
- Create `lint-shell` recipe that runs ShellCheck and shfmt
- Configure ShellCheck severity threshold (error/warning)
- Scan all `*.sh` files, `hooks/*`, and `scripts/*`
- Fail on errors, warn on style issues
- GitHub Actions installs tools and runs `just lint-shell`
- Path filtering: skip if only markdown files changed

**Files to Change**:
- Create: `justfiles/ci.just` (CI/CD recipes)
- Create: `.shellcheckrc` (configuration for repo-specific rules)
- Create: `.github/workflows/validate.yml` (calls Just recipes)
- Modify: `justfile` (import ci.just)

**Code Example (`justfiles/ci.just`)**:
```just
# CI/CD recipes for GitHub Actions and local development

# Validate shell scripts with ShellCheck and shfmt
lint-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running ShellCheck..."
  find . -type f \( -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" \) \
    ! -path "./.git/*" \
    -exec shellcheck --severity=warning {} +
  echo "✅ ShellCheck passed"

  echo "🔍 Checking shell formatting..."
  shfmt -d -i 2 -ci -bn $(find . -name "*.sh" -o -path "./hooks/*" -o -path "./scripts/*" | grep -v ".git")
  echo "✅ Shell formatting check passed"
```

**GitHub Actions Workflow (`.github/workflows/validate.yml`)**:
```yaml
name: Validate Code

on:
  pull_request:
  push:
    branches: [main, master]

jobs:
  lint-shell:
    name: Lint Shell Scripts
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Just
        uses: extractions/setup-just@v2

      - name: Install ShellCheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck

      - name: Install shfmt
        run: |
          wget -qO /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64
          chmod +x /usr/local/bin/shfmt

      - name: Run shell validation
        run: just lint-shell
```

#### Validation
- [ ] `just lint-shell` runs successfully locally
- [ ] ShellCheck catches intentionally introduced errors
- [ ] shfmt detects formatting issues
- [ ] GitHub Actions workflow triggers on shell script changes
- [ ] Workflow calls `just lint-shell` successfully
- [ ] ShellCheck configuration (.shellcheckrc) is respected

#### TODO for Stage 1
- [ ] Create `justfiles/ci.just` with `lint-shell` recipe
- [ ] Create `.shellcheckrc` with repo standards (SC2086, SC2155 handling)
- [ ] Update root `justfile` to import `justfiles/ci.just`
- [ ] Test `just lint-shell` locally
- [ ] Fix any existing ShellCheck warnings in install.sh
- [ ] Fix any existing ShellCheck warnings in uninstall.sh
- [ ] Create `.github/workflows/validate.yml` with shell linting job
- [ ] Test workflow in GitHub Actions
- [ ] Add workflow status badge to README.md
- [ ] Document `just lint-shell` in CONTRIBUTING.md

---

### Stage 2: Python Linting and Type Checking

**Stage ID**: `python-validation`
**Branch**: `feature/gh-actions-python-validation`
**Status**: Not Started
**Dependencies**: None

#### What
Create Just recipe for Python validation (ruff + mypy) and add to GitHub Actions workflow.

#### Why
scripts/planworktree.py is a critical component for plan-based development workflows. Enforcing the repository's strict Python standards (no lambdas, explicit over implicit, type hints required) maintains code quality. Using Just recipes allows developers to run the same checks locally.

#### How

**Architecture**:
1. Define `just lint-python` recipe in `justfiles/ci.just`
2. Add Python validation job to GitHub Actions that calls `just lint-python`
3. Developers can run `just lint-python` locally for same validation

**Implementation Details**:
- Create `lint-python` recipe using uv to run ruff and mypy
- Configure ruff with repository's style guide settings (docs/python-style-guide.md)
- Run ruff linter and formatter checks
- Run mypy with strict type checking
- Use Python 3.11+ (minimum version per style guide)

**Files to Change**:
- Modify: `justfiles/ci.just` (add `lint-python` recipe)
- Create: `pyproject.toml` (ruff and mypy configuration)
- Modify: `.github/workflows/validate.yml` (add Python job)
- Modify: `scripts/planworktree.py` (add type hints if missing, fix any lint issues)

**Code Example (`justfiles/ci.just` addition)**:
```just
# Lint and type-check Python scripts
lint-python:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running ruff linter..."
  uvx ruff check .
  echo "✅ Ruff linting passed"

  echo "🔍 Running ruff format check..."
  uvx ruff format --check .
  echo "✅ Ruff formatting check passed"

  echo "🔍 Running mypy type checker..."
  uvx mypy scripts/*.py --strict
  echo "✅ Mypy type checking passed"
```

**GitHub Actions Addition (`.github/workflows/validate.yml`)**:
```yaml
  lint-python:
    name: Lint Python Scripts
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Just
        uses: extractions/setup-just@v2

      - uses: astral-sh/setup-uv@v4
        with:
          version: "latest"

      - name: Run Python validation
        run: just lint-python
```

**pyproject.toml**:
```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM"]
ignore = []

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

#### Validation
- [ ] `just lint-python` runs successfully locally
- [ ] ruff catches style violations per docs/python-style-guide.md
- [ ] ruff format validates formatting
- [ ] mypy catches type errors
- [ ] scripts/planworktree.py passes all checks
- [ ] GitHub Actions workflow calls `just lint-python` successfully

#### TODO for Stage 2
- [ ] Add `lint-python` recipe to `justfiles/ci.just`
- [ ] Create `pyproject.toml` with ruff/mypy configuration
- [ ] Align ruff rules with docs/python-style-guide.md
- [ ] Test `just lint-python` locally
- [ ] Add type hints to planworktree.py if missing
- [ ] Fix any ruff violations in existing code
- [ ] Fix any mypy type errors
- [ ] Verify PEP 723 metadata is valid
- [ ] Add Python job to `.github/workflows/validate.yml`
- [ ] Test workflow in GitHub Actions
- [ ] Document `just lint-python` in CONTRIBUTING.md

---

### Stage 3: Markdown Linting and Link Checking

**Stage ID**: `markdown-validation`
**Branch**: `feature/gh-actions-markdown-validation`
**Status**: Not Started
**Dependencies**: None

#### What
Create Just recipe for markdown validation (linting + link checking) and add to GitHub Actions workflow.

#### Why
Documentation is extensive (README, CONTRIBUTING, TESTING, docs/, examples/, skills/). Ensuring markdown quality and link validity prevents user confusion and maintains professional documentation standards. Using Just recipes allows developers to run the same checks locally.

#### How

**Architecture**:
1. Define `just lint-markdown` recipe in `justfiles/ci.just`
2. Use **lychee** (Rust-based) for link checking instead of Node.js tools
3. Use markdownlint-cli2 for style (Node.js - tolerated for now, may migrate later)
4. Add markdown validation job to GitHub Actions that calls `just lint-markdown`

**Implementation Details**:
- Create `lint-markdown` recipe with markdownlint and lychee
- Use lychee for fast, concurrent link checking
- Cache external link checks to avoid rate limits
- Allow some flexibility for documentation-focused files
- Spell-checking: Scoped for future work (requires custom technical dictionary)

**Files to Change**:
- Modify: `justfiles/ci.just` (add `lint-markdown` recipe)
- Create: `.markdownlint.json` (markdown style configuration)
- Create: `lychee.toml` (lychee link checker configuration)
- Modify: `.github/workflows/validate.yml` (add markdown job)

**Code Example (`justfiles/ci.just` addition)**:
```just
# Lint markdown files and check links
lint-markdown:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Running markdownlint..."
  npx markdownlint-cli2 "**/*.md"
  echo "✅ Markdown linting passed"

  echo "🔍 Checking links with lychee..."
  lychee --config lychee.toml --no-progress '**/*.md'
  echo "✅ Link checking passed"
```

**GitHub Actions Addition (`.github/workflows/validate.yml`)**:
```yaml
  lint-markdown:
    name: Lint Markdown
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Just
        uses: extractions/setup-just@v2

      - name: Install lychee
        uses: lycheeverse/lychee-action@v2
        with:
          args: --version  # Just install, recipe will run it

      - name: Setup Node.js for markdownlint
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Run markdown validation
        run: just lint-markdown
```

**Configuration Files**:

`.markdownlint.json`:
```json
{
  "default": true,
  "MD013": false,
  "MD033": false,
  "MD041": false
}
```

`lychee.toml`:
```toml
# Lychee link checker configuration (Rust-based)
exclude_path = [".git", "node_modules"]
exclude_link_local = true
timeout = 10
max_retries = 3
max_concurrency = 8

# Ignore localhost and example domains
exclude = [
  "^http://localhost",
  "^http://127.0.0.1",
  "^https://example.com"
]

# Cache results to avoid rate limiting
cache = true
```

#### Validation
- [ ] `just lint-markdown` runs successfully locally
- [ ] markdownlint catches style issues
- [ ] lychee finds broken internal links
- [ ] lychee finds broken external links
- [ ] Link checker respects rate limits and caching
- [ ] All repository markdown files pass validation
- [ ] GitHub Actions workflow calls `just lint-markdown` successfully

#### TODO for Stage 3
- [ ] Add `lint-markdown` recipe to `justfiles/ci.just`
- [ ] Create `.markdownlint.json` configuration
- [ ] Create `lychee.toml` configuration
- [ ] Test `just lint-markdown` locally
- [ ] Fix any existing markdown lint issues
- [ ] Fix any broken links found
- [ ] Add markdown job to `.github/workflows/validate.yml`
- [ ] Test workflow in GitHub Actions
- [ ] Document `just lint-markdown` in CONTRIBUTING.md
- [ ] Note: Spell-checking scoped for future (needs custom technical dictionary)

---

### Stage 4: Installation and Integration Testing

**Stage ID**: `integration-testing`
**Branch**: `feature/gh-actions-integration-tests`
**Status**: Not Started
**Dependencies**: shell-validation, python-validation

#### What
Create Just recipe for installation testing and automate testing of install.sh and uninstall.sh scripts in clean Arch Linux environment.

#### Why
The install script is the primary user entry point. Testing in a clean Arch Linux environment ensures symlinks work correctly and verifies git hooks function properly. Using Just recipes allows developers to run the same tests locally (with containers).

#### How

**Architecture**:
1. Define `just test-install` recipe in `justfiles/ci.just`
2. Use BATS for integration testing following TESTING.md checklist
3. GitHub Actions runs tests in Arch Linux container
4. Developers can run `just test-install` locally with Docker/Podman

**Implementation Details**:
- Create `test-install` recipe that uses BATS for testing
- Test in Arch Linux container (archlinux:latest)
- Test install.sh in local mode (per-repo)
- Test install.sh in global mode (--global flag)
- Verify symlinks created correctly
- Test git hooks trigger on commits
- Test uninstall.sh cleans up properly
- Validate justfile imports work
- Test plan worktree script functionality

**Files to Change**:
- Modify: `justfiles/ci.just` (add `test-install` recipe)
- Create: `tests/integration/test-install.bats` (BATS test suite)
- Create: `tests/integration/test-uninstall.bats`
- Create: `tests/integration/test-plan-worktree.bats`
- Create: `.github/workflows/integration-tests.yml` (calls `just test-install`)

**Code Example (`justfiles/ci.just` addition)**:
```just
# Run integration tests (requires Docker/Podman)
test-install:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🧪 Running integration tests in Arch Linux container..."
  docker run --rm -v "$(pwd):/workspace" -w /workspace archlinux:latest /bin/bash -c '
    pacman -Sy --noconfirm git bats just &&
    mkdir -p /tmp/test-repo &&
    cd /tmp/test-repo &&
    git init &&
    git config user.name "Test User" &&
    git config user.email "test@example.com" &&
    bash /workspace/install.sh &&
    bats /workspace/tests/integration/test-install.bats &&
    bash /workspace/uninstall.sh &&
    bats /workspace/tests/integration/test-uninstall.bats
  '
  echo "✅ Integration tests passed"
```

**GitHub Actions Workflow (`.github/workflows/integration-tests.yml`)**:
```yaml
name: Integration Tests

on:
  pull_request:
    paths:
      - 'install.sh'
      - 'uninstall.sh'
      - 'scripts/**'
      - 'hooks/**'
      - 'justfiles/**'
      - 'tests/**'
      - '.github/workflows/integration-tests.yml'
  push:
    branches: [main, master]

jobs:
  test-install:
    name: Test Install (Arch Linux)
    runs-on: ubuntu-latest
    container:
      image: archlinux:latest

    steps:
      - name: Install dependencies
        run: pacman -Sy --noconfirm git bats just

      - uses: actions/checkout@v4

      - name: Create test repository
        run: |
          mkdir -p /tmp/test-repo
          cd /tmp/test-repo
          git init
          git config user.name "Test User"
          git config user.email "test@example.com"

      - name: Run install script
        working-directory: /tmp/test-repo
        run: bash $GITHUB_WORKSPACE/install.sh

      - name: Validate installation
        working-directory: /tmp/test-repo
        run: bats $GITHUB_WORKSPACE/tests/integration/test-install.bats

      - name: Test uninstall
        working-directory: /tmp/test-repo
        run: |
          bash $GITHUB_WORKSPACE/uninstall.sh
          bats $GITHUB_WORKSPACE/tests/integration/test-uninstall.bats

  test-plan-worktree:
    name: Test Plan Worktree Script
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Just
        uses: extractions/setup-just@v2

      - uses: astral-sh/setup-uv@v4

      - name: Create test plan file
        run: |
          mkdir -p .claude/plans
          cp .claude/plans/2025-11-17-notification-hooks-waiting-for-input.md .claude/plans/test-plan.md

      - name: Test plan worktree commands
        run: |
          chmod +x scripts/planworktree.py
          ./scripts/planworktree.py list .claude/plans/test-plan.md
          ./scripts/planworktree.py status .claude/plans/test-plan.md
```

**BATS Test Example** (`tests/integration/test-install.bats`):
```bash
#!/usr/bin/env bats

setup() {
  # Runs before each test
  export TEST_REPO="/tmp/test-repo"
}

@test "justfile created" {
  [ -f "$TEST_REPO/justfile" ]
}

@test "justfile imports base recipes" {
  grep -q "_base.just" "$TEST_REPO/justfile"
}

@test ".claude/commands symlinked" {
  [ -L "$TEST_REPO/.claude/commands" ]
}

@test "pre-commit hook installed" {
  [ -f "$TEST_REPO/.git/hooks/pre-commit" ]
  [ -x "$TEST_REPO/.git/hooks/pre-commit" ]
}

@test "context.yaml created" {
  [ -f "$TEST_REPO/.claude/context.yaml" ]
}

@test "plans directory created" {
  [ -d "$TEST_REPO/.claude/plans" ]
}
```

#### Validation
- [ ] `just test-install` runs successfully locally (with Docker)
- [ ] Tests run successfully in Arch Linux container
- [ ] Install script creates all expected files
- [ ] Symlinks point to correct locations
- [ ] Git hooks are executable
- [ ] Uninstall script removes all files
- [ ] Plan worktree script passes all tests
- [ ] GitHub Actions workflow runs tests in Arch container

#### TODO for Stage 4
- [ ] Add `test-install` recipe to `justfiles/ci.just`
- [ ] Create `tests/integration/` directory
- [ ] Write `test-install.bats` test suite
- [ ] Write `test-uninstall.bats` test suite
- [ ] Write `test-plan-worktree.bats` test suite (optional)
- [ ] Test `just test-install` locally with Docker
- [ ] Create `.github/workflows/integration-tests.yml`
- [ ] Test workflow in GitHub Actions with Arch container
- [ ] Verify all tests pass
- [ ] Add integration test badge to README.md
- [ ] Document `just test-install` in CONTRIBUTING.md

---

### Stage 5: Pull Request Validation Workflow

**Stage ID**: `pr-validation`
**Branch**: `feature/gh-actions-pr-validation`
**Status**: Not Started
**Dependencies**: shell-validation, python-validation, markdown-validation, integration-testing

#### What
Create orchestration workflow that runs all Just-based validations on pull requests and provides consolidated feedback.

#### Why
Single workflow that coordinates all checks, enforces quality gates, and provides clear feedback to contributors before merge. All checks use Just recipes for local-CI parity.

#### How

**Architecture**:
1. Meta-workflow that runs all `just lint-*` and `just test-*` commands
2. Uses **cocogitto** (Rust) for conventional commit checking instead of Node.js tools
3. Aggregates results and blocks merge if failures
4. Auto-labels PRs based on changed files

**Implementation Details**:
- Run all validation jobs in parallel
- Check conventional commit format on PR title (using cocogitto)
- Validate CHANGELOG.md updated for feature branches
- Require all checks pass before merge allowed
- Auto-label PRs based on changed files (GitHub labeler)

**Files to Change**:
- Create: `.github/workflows/pr-checks.yml` (orchestration)
- Create: `cog.toml` (cocogitto conventional commit configuration)
- Create: `.github/labeler.yml` (auto-labeling configuration)

**Code Example (`.github/workflows/pr-checks.yml`)**:
```yaml
name: Pull Request Checks

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

jobs:
  # Meta job that requires all other checks
  all-checks:
    name: All Validation Checks
    runs-on: ubuntu-latest
    if: github.event.pull_request.draft == false
    needs:
      - validate
      - integration-tests
      - commit-lint
      - changelog-check
    steps:
      - name: All checks passed
        run: echo "✅ All validation checks passed"

  # Run all Just-based validations
  validate:
    uses: ./.github/workflows/validate.yml

  integration-tests:
    uses: ./.github/workflows/integration-tests.yml

  commit-lint:
    name: Conventional Commits Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install cocogitto (Rust-based)
        run: |
          curl -L https://github.com/cocogitto/cocogitto/releases/latest/download/cocogitto-x86_64-unknown-linux-musl -o /usr/local/bin/cog
          chmod +x /usr/local/bin/cog

      - name: Check conventional commits
        run: cog check --from-latest-tag || cog check HEAD~1

  changelog-check:
    name: CHANGELOG Updated
    runs-on: ubuntu-latest
    if: startsWith(github.head_ref, 'feature/') || startsWith(github.head_ref, 'feat/')
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check CHANGELOG.md updated
        run: |
          if git diff origin/${{ github.base_ref }}...HEAD --name-only | grep -q "CHANGELOG.md"; then
            echo "✅ CHANGELOG.md updated"
          else
            echo "❌ CHANGELOG.md not updated for feature branch"
            exit 1
          fi

  auto-label:
    name: Auto Label PR
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/labeler@v5
```

**Cocogitto Configuration (`cog.toml`)**:
```toml
# Conventional commit configuration (Rust-based tool)
[changelog]
path = "CHANGELOG.md"

[commit_types]
feat = "Features"
fix = "Bug Fixes"
docs = "Documentation"
chore = "Chores"
refactor = "Refactoring"
test = "Tests"
```

**Auto-labeler Configuration (`.github/labeler.yml`)**:
```yaml
documentation:
  - changed-files:
    - any-glob-to-any-file: '**/*.md'
  - changed-files:
    - any-glob-to-any-file: 'docs/**/*'

shell:
  - changed-files:
    - any-glob-to-any-file: '**/*.sh'
  - changed-files:
    - any-glob-to-any-file: 'hooks/**/*'

python:
  - changed-files:
    - any-glob-to-any-file: '**/*.py'
  - changed-files:
    - any-glob-to-any-file: 'pyproject.toml'

ci:
  - changed-files:
    - any-glob-to-any-file: '.github/**/*'

justfile:
  - changed-files:
    - any-glob-to-any-file: '**/*.just'
  - changed-files:
    - any-glob-to-any-file: 'justfiles/**/*'
```

#### Validation
- [ ] All validation and test jobs run in parallel
- [ ] PR blocked if any check fails
- [ ] Cocogitto conventional commit validation works (Rust-based)
- [ ] CHANGELOG check enforced on feature branches
- [ ] Auto-labeling works based on changed files
- [ ] Status check summary displayed on PR
- [ ] All checks use Just recipes (validate.yml and integration-tests.yml)

#### TODO for Stage 5
- [ ] Create `.github/workflows/pr-checks.yml`
- [ ] Create `cog.toml` for cocogitto configuration
- [ ] Create `.github/labeler.yml` for auto-labeling
- [ ] Test cocogitto locally for commit validation
- [ ] Test PR workflow with sample PR
- [ ] Configure branch protection rules in GitHub settings
- [ ] Set required checks: validate, integration-tests, commit-lint, changelog-check
- [ ] Document PR requirements in CONTRIBUTING.md
- [ ] Add PR checks badge to README.md

---

### Stage 6: Release and Changelog Automation

**Stage ID**: `release-automation`
**Branch**: `feature/gh-actions-release-automation`
**Status**: Not Started
**Dependencies**: None (can run in parallel)

#### What
Create Just recipe for release management using git-cliff (Rust) and automate GitHub release creation.

#### Why
Streamline the release process using Rust-based tooling (git-cliff), ensure consistent release notes, and automate changelog integration with GitHub releases. Using Just recipes allows developers to test release processes locally.

#### How

**Architecture**:
1. Define `just release` recipe using git-cliff for changelog management
2. GitHub Actions workflow triggered on version tags calls `just release`
3. Use git-cliff (Rust) instead of Node.js semantic-release tools
4. Developers can run `just release` locally to test

**Implementation Details**:
- Trigger on semantic version tags (v1.2.3)
- Validate tag matches semantic versioning format
- Use git-cliff to generate/update CHANGELOG.md
- Extract relevant section for GitHub release body
- Create GitHub release with changelog content via GitHub API
- Attach install.sh and uninstall.sh as release assets

**Files to Change**:
- Modify: `justfiles/ci.just` (add `release` recipe)
- Create: `cliff.toml` (git-cliff configuration)
- Create: `.github/workflows/release.yml` (calls `just release`)

**Code Example (`justfiles/ci.just` addition)**:
```just
# Generate or update CHANGELOG.md using git-cliff (Rust-based)
changelog:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "📝 Generating changelog with git-cliff..."
  git-cliff --config cliff.toml --output CHANGELOG.md
  echo "✅ Changelog generated"

# Generate release notes for a specific tag (Argo-compatible: no GitHub dependency)
release-notes TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate semantic version tag format
  if [[ ! "{{TAG}}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid tag format: {{TAG}}" >&2
    echo "Expected format: v1.2.3" >&2
    exit 1
  fi

  # Generate changelog for this version only
  git-cliff --config cliff.toml --unreleased --tag "{{TAG}}" --strip all

# Create GitHub release using gh CLI (works locally and in any CI)
github-release TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate tag format first
  just release-notes "{{TAG}}" > /dev/null

  echo "📝 Generating release notes with git-cliff..."
  NOTES=$(just release-notes "{{TAG}}")

  echo "🚀 Creating GitHub release for {{TAG}}..."
  gh release create "{{TAG}}" \
    --title "Release {{TAG}}" \
    --notes "$NOTES" \
    install.sh uninstall.sh

  echo "✅ Release {{TAG}} created with assets"

# Full release workflow (for local testing)
release TAG: (release-notes TAG) (github-release TAG)
  @echo "✅ Release {{TAG}} complete"
```

**git-cliff Configuration (`cliff.toml`)**:
```toml
# git-cliff configuration for changelog generation (Rust-based)
[changelog]
header = """
# Changelog\n
All notable changes to claude-dotfiles will be documented in this file.\n
"""
body = """
{% for group, commits in commits | group_by(attribute="group") %}
    ## {{ group | upper_first }}
    {% for commit in commits %}
        - {{ commit.message | upper_first }} ({{ commit.id | truncate(length=7, end="") }})
    {%- endfor %}
{% endfor %}\n
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^docs", group = "Documentation" },
  { message = "^chore", group = "Chores" },
  { message = "^refactor", group = "Refactoring" },
  { message = "^test", group = "Tests" },
]
```

**GitHub Actions Workflow (`.github/workflows/release.yml`)**:
```yaml
name: Release

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'

permissions:
  contents: write

jobs:
  create-release:
    name: Create GitHub Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history for git-cliff

      - name: Install Just
        uses: extractions/setup-just@v2

      - name: Install git-cliff
        run: |
          curl -L https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-x86_64-unknown-linux-musl.tar.gz | tar xz
          sudo mv git-cliff-*/git-cliff /usr/local/bin/
          chmod +x /usr/local/bin/git-cliff

      - name: Install GitHub CLI
        run: |
          type -p gh > /dev/null || (
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh -y
          )

      - name: Create GitHub release using Just recipe
        run: just github-release "$GITHUB_REF_NAME"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Validation
- [ ] `just changelog` generates CHANGELOG.md locally using git-cliff
- [ ] `just release-notes <tag>` validates tag format and generates notes
- [ ] `just release-notes <tag>` works without GitHub dependency (Argo-compatible)
- [ ] `just github-release <tag>` creates release using gh CLI
- [ ] `just release <tag>` runs full workflow (notes + GitHub release)
- [ ] git-cliff generates proper release notes from conventional commits
- [ ] GitHub Actions workflow triggers on valid version tags
- [ ] GitHub release created successfully with changelog content
- [ ] Release includes install.sh and uninstall.sh as assets
- [ ] Invalid tags are rejected by `just release-notes`
- [ ] Can test releases locally with gh CLI and personal repo

#### TODO for Stage 6
- [ ] Add `changelog`, `release-notes`, `github-release`, and `release` recipes to `justfiles/ci.just`
- [ ] Create `cliff.toml` for git-cliff configuration
- [ ] Align cliff.toml with cog.toml commit types
- [ ] Test `just changelog` locally with git-cliff
- [ ] Test `just release-notes v0.0.1` locally (no GitHub dependency)
- [ ] Test `just github-release v0.0.1` locally with gh CLI (optional, needs GITHUB_TOKEN)
- [ ] Create `.github/workflows/release.yml` with gh CLI installation
- [ ] Test release workflow with test tag
- [ ] Verify release assets are attached correctly
- [ ] Document release process in CONTRIBUTING.md
- [ ] Document `just changelog` and `just release-notes` usage for maintainers
- [ ] Note: `release-notes` recipe is Argo-compatible (no GitHub-specific dependencies)

---

## Testing Strategy

### Unit Tests
**Coverage Goal**: N/A (primarily workflow configuration and integration tests)

### Integration Tests
**Scenarios**:
- All Just-based validations execute successfully locally and in CI
- Shell validation catches intentional errors (`just lint-shell`)
- Python validation catches type errors and lint violations (`just lint-python`)
- Markdown validation finds broken links (`just lint-markdown`)
- Install tests work in Arch Linux container (`just test-install`)
- PR validation blocks merge on failures
- Release workflow creates proper GitHub releases using git-cliff

### Manual Testing

**Local Testing (Just Recipes)**:
- [ ] Run `just lint-shell` locally → verify ShellCheck works
- [ ] Run `just lint-python` locally → verify ruff and mypy work
- [ ] Run `just lint-markdown` locally → verify lychee link checking works
- [ ] Run `just test-install` locally with Docker → verify BATS tests pass
- [ ] Run `just changelog` locally → verify git-cliff generates changelog

**Workflow Testing**:
- [ ] Create test PR with shell script errors → verify `just lint-shell` fails in CI
- [ ] Create test PR with Python lint errors → verify `just lint-python` fails in CI
- [ ] Create test PR with broken markdown links → verify `just lint-markdown` fails in CI
- [ ] Create test PR with valid changes → verify all workflows pass
- [ ] Test conventional commits with cocogitto locally

**End-to-End Testing**:
- [ ] Fork repository, enable Actions, create PR with errors
- [ ] Verify status checks block merge
- [ ] Fix errors locally using Just recipes, verify checks pass in CI and merge allowed
- [ ] Create test tag v0.0.1 → verify release created with git-cliff notes

## Deployment Plan

### Pre-deployment
- [ ] All Just recipes tested locally (lint-shell, lint-python, lint-markdown, test-install)
- [ ] All workflows tested in fork/branch
- [ ] Update CONTRIBUTING.md with Just recipe usage and CI/CD requirements
- [ ] Update README.md with Just recipes documentation and status badges
- [ ] Create pull request with justfiles/ci.just and all workflows
- [ ] Review workflow configurations for security

### Staging Deployment
- [ ] Merge justfiles/ci.just and workflow files to main branch
- [ ] Configure GitHub repository settings:
  - [ ] Enable Actions
  - [ ] Configure branch protection (require status checks)
  - [ ] Set required checks: validate (all lint jobs), integration-tests, commit-lint, changelog-check
- [ ] Test workflows on actual PRs
- [ ] Verify Just recipes run same checks as CI

### Production Deployment
- [ ] Verify all workflows run successfully on real PRs
- [ ] Verify all Just recipes work locally for contributors
- [ ] Enable required status checks for main/master branch
- [ ] Document workflow behavior and Just recipes in README.md
- [ ] Document how to run Just recipes locally in CONTRIBUTING.md
- [ ] Announce CI/CD integration in CHANGELOG.md (using git-cliff)

### Rollback Plan
If issues detected:
1. Disable specific workflow by removing from `.github/workflows/`
2. Remove from required status checks in branch protection
3. Just recipes remain functional locally for debugging
4. Fix issues in separate PR
5. Re-enable after validation

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Workflows timeout on slow runners | Low | Medium | Set timeout limits, optimize caching, Just recipes are fast |
| ShellCheck false positives | Medium | Low | Configure .shellcheckrc with project-specific rules |
| Integration tests fail in Arch container | Low | Medium | Test locally with `just test-install` before pushing |
| Link checker (lychee) rate limited by external sites | Medium | Low | Use lychee's built-in caching and retry logic in lychee.toml |
| GitHub Actions quota exhausted (free tier) | Low | Medium | Optimize path filtering, use caching, monitor usage |
| Required checks too strict | Medium | Medium | Start with warnings, gradually make required |
| Release automation with git-cliff misconfigured | Low | Medium | Test `just changelog` locally, validate cliff.toml format |
| Python mypy too strict for simple scripts | Medium | Low | Configure mypy with pragmatic strictness, allow # type: ignore where needed |
| BATS tests complex to maintain | Medium | Medium | Keep tests simple and focused, document test patterns |
| Dependency on external GitHub Actions | Medium | Medium | Pin action versions, minimal external dependencies |
| Just recipes work locally but fail in CI | Low | High | Ensure same tool versions in CI and local docs, use containers for parity |
| cocogitto conventional commits too strict | Low | Low | Configure cog.toml with project-specific commit types |
| Developers don't have Just/tools installed locally | Medium | Medium | Document installation in CONTRIBUTING.md, provide setup script |

## Dependencies

### Upstream Dependencies
- [ ] GitHub Actions enabled for repository
- [ ] Just (task runner) - installed in CI and documented for local dev
- [ ] ShellCheck (Haskell) - installed in CI
- [ ] shfmt (Go) - installed in CI
- [ ] ruff (Rust) - installed via uv in CI
- [ ] mypy (Python) - installed via uv in CI
- [ ] lychee (Rust) - installed in CI
- [ ] markdownlint-cli2 (Node.js) - tolerated, may migrate later
- [ ] BATS (Bash testing) - for integration tests
- [ ] git-cliff (Rust) - for changelog and releases
- [ ] cocogitto (Rust) - for conventional commits

### Downstream Impact
- Contributors: Must pass all Just-based checks before merge, can run same checks locally
- Contributors: Need Just and tools installed for local development
- Maintainers: Automated release process with git-cliff reduces manual work
- Maintainers: Can run `just changelog` to generate/update CHANGELOG.md
- Users: Higher confidence in release quality
- Documentation: README, CONTRIBUTING, and new CI/CD docs needed

## Open Questions

- [ ] Should we add code coverage reporting for Python scripts?
- [ ] Do we want automated dependency updates (Dependabot/Renovate)?
- [ ] Should we add a workflow to validate example justfiles syntax?
- [ ] Do we want to auto-generate contributor documentation from workflows?
- [ ] Should we add performance benchmarks for install script?

## Success Criteria

- [ ] All CI tasks defined as Just recipes in justfiles/ci.just
- [ ] All shell scripts pass ShellCheck validation (`just lint-shell`)
- [ ] All Python scripts pass ruff and mypy validation (`just lint-python`)
- [ ] All markdown files pass lint and link checks (`just lint-markdown`)
- [ ] Install/uninstall scripts tested in Arch Linux (`just test-install`)
- [ ] Developers can run all checks locally using Just commands
- [ ] GitHub Actions workflows call Just recipes (not duplicate logic)
- [ ] PR checks run automatically and block merge on failures
- [ ] Release workflow uses git-cliff for changelog generation
- [ ] Conventional commits enforced with cocogitto (Rust-based)
- [ ] Rust-based tools used where possible (lychee, git-cliff, cocogitto, ruff/uv)
- [ ] Documentation updated with Just recipe usage and CI/CD requirements
- [ ] Status badges added to README.md
- [ ] CONTRIBUTING.md explains how to run Just recipes locally and fix CI failures

## Future Migration Path: Argo Workflows

### Overview

The Justfile-centric architecture enables future migration to Argo Workflows (Kubernetes-native CI/CD) with minimal changes to core logic. All CI tasks are Just recipes, with GitHub Actions providing only thin orchestration. This design minimizes vendor lock-in.

**Migration Risk**: ✅ **LOW** - All CI logic is in portable Just recipes

### Migration Readiness

**Already Argo-Compatible** ✅:
- All CI logic in Just recipes (not workflow YAML)
- Container-based integration testing (archlinux:latest)
- Standard CLI tools (shellcheck, ruff, lychee, git-cliff, etc.)
- GitHub releases abstracted to `gh` CLI in `github-release` recipe
- Release notes generation (`release-notes`) has zero GitHub dependencies
- CI contract documented (`.claude/ci-contract.md`)

**Will Require Adaptation** ⚠️:
- Workflow orchestration syntax (GitHub Actions YAML → Argo Workflow templates)
- Trigger mechanisms (GitHub webhooks → Argo Events)
- Secrets management (GitHub Actions secrets → Kubernetes secrets)
- PR auto-labeling (GitHub Actions labeler → custom webhook handler)
- Status checks integration (GitHub native → custom reporting)

### Argo Workflow Conceptual Mapping

**Current GitHub Actions** (`.github/workflows/validate.yml`):
```yaml
jobs:
  lint-shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Just
        uses: extractions/setup-just@v2
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Run validation
        run: just lint-shell
```

**Future Argo Workflow** (`argo-workflows/validate.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: validate-
spec:
  entrypoint: lint-shell
  templates:
  - name: lint-shell
    container:
      image: myorg/ci-tools:latest  # Pre-installed: just, shellcheck, shfmt
      command: [just, lint-shell]
      workingDir: /workspace
      volumeMounts:
      - name: source
        mountPath: /workspace
  volumes:
  - name: source
    # Source code from git clone init container or artifact
```

**Key Point**: Same `just lint-shell` command runs identically in both systems.

**Benefits of Current Architecture for Argo**:
1. ✅ Just recipes are 100% portable between CI systems
2. ✅ Can create custom container images with all tools pre-installed
3. ✅ Container-based testing already proven with BATS tests
4. ✅ No GitHub Actions-specific logic in core CI tasks
5. ✅ `release-notes` recipe works in any environment (no GitHub API)
6. ✅ Local testing matches CI exactly (`just <task>`)

### Migration Timeline Estimate

**Phase 1: Preparation** (Already included in this plan)
- **Duration**: Included in current implementation (2-4 hours for Argo-specific improvements)
- **Tasks**:
  - ✅ Abstract GitHub releases to `gh` CLI (Stage 6)
  - ✅ Split release logic: `release-notes` (portable) + `github-release` (GitHub-specific)
  - ✅ Document CI contract in `.claude/ci-contract.md`
  - ✅ Keep all CI logic in Just recipes
- **Deliverables**:
  - Argo-ready Just recipes
  - CI contract documentation
  - Migration review documents

**Phase 2: Argo Implementation** (Future, when ready for migration)
- **Duration**: 1-2 weeks
- **Tasks**:
  - Set up Argo Workflows in Kubernetes cluster
  - Create custom CI tools container image (Dockerfile with just, shellcheck, ruff, etc.)
  - Translate GitHub Actions workflows to Argo Workflow templates
  - Configure Argo Events for GitHub webhook triggers
  - Set up Kubernetes secrets for GITHUB_TOKEN
  - Implement custom PR status reporting
  - Migrate path filtering logic to Argo event filters
- **Deliverables**:
  - Argo Workflow templates for all stages
  - Custom container image published to registry
  - Argo Events sensors configured

**Phase 3: Parallel Running** (Future, validation phase)
- **Duration**: 1-2 weeks
- **Tasks**:
  - Run both GitHub Actions and Argo Workflows in parallel
  - Validate Argo results match GitHub Actions results
  - Compare performance and reliability
  - Build team confidence in Argo system
  - Document any differences or issues
- **Deliverables**:
  - Validation report comparing both systems
  - Team confidence in Argo Workflows

**Phase 4: Migration** (Future, cutover phase)
- **Duration**: 1 week
- **Tasks**:
  - Switch primary CI to Argo Workflows
  - Keep GitHub Actions as backup/fallback
  - Monitor Argo performance and reliability
  - Decommission GitHub Actions after confidence period
- **Deliverables**:
  - Primary CI running on Argo Workflows
  - Documentation updated for new system

**Total Future Migration Effort**: 2-4 weeks (excluding preparation already in current plan)

### Argo-Specific Improvements Already in This Plan

This GitHub Actions plan includes specific improvements for Argo compatibility:

1. **Separated release concerns** (Stage 6):
   - `release-notes` - Pure git-cliff logic (works anywhere, including Argo)
   - `github-release` - GitHub API interaction via `gh` CLI
   - When migrating to Argo: Keep `release-notes`, replace `github-release` with Kubernetes API

2. **Tool abstraction**:
   - All GitHub interactions use `gh` CLI (not Actions-specific APIs)
   - Easy to replace `gh` CLI with other tools in Argo

3. **Container-first testing**:
   - Integration tests already use containers (Arch Linux)
   - Pattern maps directly to Argo's container-native approach

4. **CI contract documentation**:
   - `.claude/ci-contract.md` explicitly defines orchestrator requirements
   - Serves as specification for both GitHub Actions and future Argo implementation

### Migration References

- **Full migration analysis**: `.claude/plans/2025-11-18-argo-workflows-migration-review.md`
- **Specific improvements**: `.claude/plans/2025-11-18-argo-migration-plan-improvements.md`
- **CI contract**: `.claude/ci-contract.md`
- **Argo Workflows**: https://argoproj.github.io/argo-workflows/
- **Argo Events**: https://argoproj.github.io/argo-events/

### Anti-Patterns to Avoid (Would Hurt Argo Migration)

During implementation of this plan, do NOT:

1. ❌ Put business logic in workflow YAML files (keep it in Just recipes)
2. ❌ Use GitHub Actions expressions heavily (`${{ }}` syntax for logic)
3. ❌ Rely on GitHub Actions cache/artifacts for critical paths
4. ❌ Use GitHub Actions composite actions for core CI logic
5. ❌ Hard-code GitHub-specific APIs in shell scripts (use `gh` CLI abstraction)
6. ❌ Make Just recipes depend on GitHub Actions environment variables

**Follow these principles instead**:
1. ✅ All logic in Just recipes
2. ✅ Workflows only orchestrate (setup → invoke Just → report)
3. ✅ Use standard tools available in any Linux environment
4. ✅ Test all Just recipes locally with `just <task>`
5. ✅ Document orchestrator contracts explicitly

## Overall TODO List

### Pre-Implementation
- [ ] Review and approve plan
- [ ] Clarify open questions
- [ ] Set up worktrees for stages: `./scripts/planworktree.py setup-all .claude/plans/2025-11-18-github-actions-integration.md`

### Implementation (per stage)
- [ ] Stage 1: Shell Script Validation - See Stage 1 TODO above
- [ ] Stage 2: Python Linting and Type Checking - See Stage 2 TODO above
- [ ] Stage 3: Markdown Linting and Link Checking - See Stage 3 TODO above
- [ ] Stage 4: Installation and Integration Testing - See Stage 4 TODO above
- [ ] Stage 5: Pull Request Validation - See Stage 5 TODO above
- [ ] Stage 6: Release Automation - See Stage 6 TODO above

### Integration & Testing
- [ ] Merge all stage branches to integration branch
- [ ] Test all workflows together
- [ ] Verify no conflicts between workflows
- [ ] Test end-to-end PR flow

### Documentation & Deployment
- [ ] Update README.md with status badges
- [ ] Update CONTRIBUTING.md with CI requirements
- [ ] Update CHANGELOG.md with CI/CD feature
- [ ] Create pull request for review
- [ ] Configure GitHub repository settings
- [ ] Enable branch protection with required checks
- [ ] Monitor first few PRs with new workflows

## References

### CI/CD & GitHub Actions
- GitHub Actions Documentation: https://docs.github.com/en/actions
- Just (task runner): https://just.systems/
- Semantic Versioning: https://semver.org/
- Conventional Commits: https://www.conventionalcommits.org/

### Linting & Validation Tools
- ShellCheck: https://www.shellcheck.net/
- shfmt: https://github.com/mvdan/sh
- ruff (Rust-based Python linter): https://docs.astral.sh/ruff/
- mypy: https://mypy.readthedocs.io/
- lychee (Rust link checker): https://github.com/lycheeverse/lychee
- markdownlint: https://github.com/DavidAnson/markdownlint

### Testing & Automation
- BATS (Bash Automated Testing): https://github.com/bats-core/bats-core
- git-cliff (Rust changelog generator): https://git-cliff.org/
- cocogitto (Rust conventional commits): https://github.com/cocogitto/cocogitto

### Rust Tooling Ecosystem
- uv (Rust-based Python package manager): https://github.com/astral-sh/uv
- Rust-based tooling benefits: Performance, single binary distribution, no runtime dependencies
