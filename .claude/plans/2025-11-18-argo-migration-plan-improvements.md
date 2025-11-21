# GitHub Actions Plan Improvements for Argo Migration Readiness

**Based on Review**: `.claude/plans/2025-11-18-argo-workflows-migration-review.md`
**Target Plan**: `.claude/plans/2025-11-18-github-actions-integration.md`

## Quick Summary

Your plan is **excellent** for Argo migration! These improvements make it even better:

1. ✅ **Abstract GitHub releases to Just recipe** (Stage 6)
2. ✅ **Document CI contract** (New document)
3. ✅ **Add Argo migration notes to plan** (Plan update)

## Specific Changes to Make

### 1. Stage 6 Improvement: Abstract GitHub Releases

**File**: `.claude/plans/2025-11-18-github-actions-integration.md` (Stage 6)

**Current approach** (Line 968):

```just
# Create a release (validate tag, generate notes, create GitHub release)
release TAG:
  #!/usr/bin/env bash
  set -euo pipefail
  # ... validation ...
  NOTES=$(git-cliff --config cliff.toml --unreleased --tag "{{TAG}}" --strip all)
  echo "✅ Release notes generated"
  echo "Creating GitHub release..."
  # Note: In CI, this would use GitHub API; locally it's a dry-run
```

**✅ Improved approach** (Argo-ready):

```just
# Generate release notes for a tag
release-notes TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate semantic version tag format
  if [[ ! "{{TAG}}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid tag format: {{TAG}}"
    echo "Expected format: v1.2.3"
    exit 1
  fi

  # Generate changelog for this version
  git-cliff --config cliff.toml --unreleased --tag "{{TAG}}" --strip all

# Create GitHub release (works in any CI or locally)
github-release TAG:
  #!/usr/bin/env bash
  set -euo pipefail

  # Validate tag format
  just release-notes "{{TAG}}" > /dev/null

  # Generate release notes
  NOTES=$(just release-notes "{{TAG}}")

  # Create release using gh CLI (works locally and in any CI)
  gh release create "{{TAG}}" \
    --title "Release {{TAG}}" \
    --notes "$NOTES" \
    install.sh uninstall.sh

  echo "✅ Release {{TAG}} created with assets"

# Full release workflow (local testing)
release TAG: (release-notes TAG) (github-release TAG)
  @echo "✅ Release {{TAG}} complete"
```

**Why this is better**:

- ✅ Separates concerns (notes generation vs. GitHub API)
- ✅ `release-notes` works in any CI (no GitHub dependency)
- ✅ `github-release` uses `gh` CLI (consistent interface, works locally)
- ✅ Can test locally: `just release-notes v1.0.0`
- ✅ Argo migration: Just replace `gh` CLI with Kubernetes API client

**GitHub Actions workflow adjustment** (`.github/workflows/release.yml`, Line 1051):

```yaml
      - name: Install gh CLI
        run: |
          type -p gh > /dev/null || (
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh -y
          )

      - name: Create release
        run: just github-release "$GITHUB_REF_NAME"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Benefits**:

- Same Just recipe works in GHA and future Argo Workflows
- Local testing: `GITHUB_TOKEN=... just github-release v1.0.0`
- Easy to replace `gh` CLI with other tools if needed

### 2. New Document: CI Contract

**File**: `.claude/ci-contract.md` (new file)

```markdown
# CI/CD Contract

This document defines the contract between CI orchestrators (GitHub Actions, Argo Workflows, etc.) and the Just-based CI tasks.

## Purpose

All CI logic lives in Just recipes (`justfiles/ci.just`). Orchestrators simply:
1. Set up the environment
2. Invoke `just <task>`
3. Report results

This ensures:
- ✅ Local-CI parity (developers run same commands)
- ✅ No vendor lock-in (Just recipes work anywhere)
- ✅ Easy migration between orchestrators

## Required Environment

### Operating System
- Linux (Ubuntu 20.04+ or Arch Linux)
- Bash 5.0+

### Tools in PATH
- `just` (0.11.0+)
- `git` (2.30+)
- `bash`

### Task-Specific Dependencies

| Just Task | Required Tools | Can Pre-install in Image? |
|-----------|---------------|---------------------------|
| `lint-shell` | shellcheck, shfmt | ✅ Yes |
| `lint-python` | uv (installs ruff/mypy) | ✅ Yes (uv only) |
| `lint-markdown` | lychee, node, npm | ✅ Yes |
| `test-install` | docker or podman, bats | ✅ Yes |
| `release-notes` | git-cliff | ✅ Yes |
| `github-release` | gh CLI, git-cliff | ✅ Yes |

### Environment Variables

#### Required for All Tasks
- `HOME` - User home directory (for tool caches)

#### Required for Specific Tasks
- `GITHUB_TOKEN` - Required for `github-release` task
  - Used by `gh` CLI for GitHub API authentication
  - Must have `repo` and `workflow` scopes for releases

#### Optional
- `CI` - Set to `true` in CI environments (for conditional behavior)

## Inputs

### Source Code
- Working directory must be repository root
- Git history required for: `release-notes`, `github-release`
- Clean checkout required for: `test-install`

### Parameters
Just recipes use explicit parameters (not implicit env vars where possible):

```bash

## Good: Explicit parameter

just release-notes v1.2.3

## Avoid: Implicit environment variable

TAG=v1.2.3 just release-notes  # Don't do this
```

## Outputs

### Exit Codes
- `0` - Success
- Non-zero - Failure (check stdout/stderr for details)

### Stdout/Stderr
- Validation failures printed to stderr
- Progress messages printed to stdout
- Format: Emoji + message (e.g., `✅ Shell linting passed`)

### Artifacts
Current tasks do NOT produce artifacts, but if added:

| Task | Artifact | Path | Format |
|------|----------|------|--------|
| (future) `test-install` | Test reports | `reports/bats.xml` | JUnit XML |
| (future) `lint-*` | Lint reports | `reports/lint.json` | JSON |

## Orchestrator Requirements

### Minimal Orchestrator (Any CI)

```yaml

## Pseudocode - works in any CI system

steps:

  - checkout: repository
  - install: just, docker  # Minimal requirements
  - run: just test-install
```

### GitHub Actions Orchestrator

```yaml

## .github/workflows/validate.yml

jobs:
  lint:
    runs-on: ubuntu-latest
```

steps:

```text
    - uses: actions/checkout@v4
    - name: Install Just
        uses: extractions/setup-just@v2
    - run: just lint-shell
```

### Argo Workflows Orchestrator (Future)

```yaml

## argo-workflows/validate.yaml

templates:

  - name: lint-shell
    container:
      image: myorg/ci-tools:latest  # Pre-installed just, shellcheck
      command: [just, lint-shell]
      workingDir: /workspace
```

## Triggers and Path Filtering

### Trigger Recommendations

| Task | Trigger On | Skip If |
|------|-----------|---------|
| `lint-shell` | `*.sh`, `hooks/*`, `scripts/*` changed | Only `*.md` changed |
| `lint-python` | `*.py`, `pyproject.toml` changed | Only `*.md`, `*.sh` changed |
| `lint-markdown` | `*.md` changed | Only `*.py`, `*.sh` changed |
| `test-install` | `install.sh`, `uninstall.sh`, `scripts/*` changed | Only `*.md` changed |
| `github-release` | Tag `v*` pushed | N/A |

### Path Filter Configuration

Recommended paths to watch:

```yaml

## Example: GitHub Actions path filtering

on:
  pull_request:
    paths:
    - '**.sh'          # lint-shell
    - 'hooks/**'       # lint-shell
    - 'scripts/**'     # lint-shell, test-install
    - '**.py'          # lint-python
    - 'pyproject.toml' # lint-python
    - '**.md'          # lint-markdown
    - 'install.sh'     # test-install
    - 'uninstall.sh'   # test-install
```

## Secrets Management

### Required Secrets

| Secret | Used By | Purpose | Scopes |
|--------|---------|---------|--------|
| `GITHUB_TOKEN` | `github-release` | Create releases | `repo`, `workflow` |

### Accessing Secrets

Orchestrators must provide secrets as environment variables:

```bash

## GitHub Actions

GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} just github-release v1.0.0

## Argo Workflows (future)

env:

  - name: GITHUB_TOKEN
    valueFrom:
      secretKeyRef:
        name: github-credentials
        key: token
```

## Migration Guide

### From GitHub Actions to Argo Workflows

1. **Create CI tools container image**:

   ```dockerfile
   FROM ubuntu:22.04
   RUN apt-get update && apt-get install -y \
     just shellcheck git gh

## ... more tools
   ```

2. **Replace GHA-specific integrations**:
   - `actions/checkout@v4` → Init container with git clone
   - `actions/labeler@v5` → Custom Kubernetes webhook handler
   - Secrets → Kubernetes secrets

3. **Convert workflow syntax**:

   ```yaml

## GHA

    - run: just lint-shell

## Argo

    - name: lint-shell

     template: just-task
     arguments:
       parameters:
      - name: task
         value: lint-shell
   ```

4. **Set up Argo Events** for GitHub webhooks

5. **Test in parallel** before switching

### From Argo Workflows to Other CI

Same process in reverse. Just recipes are portable!

## Validation

To validate an orchestrator meets the contract:

```bash

## 1. Check tool availability

just --version
git --version
shellcheck --version

## 2. Run each task

just lint-shell
just lint-python
just lint-markdown

## 3. Verify test tasks work

docker --version  # or podman
just test-install

## 4. Check release tasks (read-only)

just release-notes v0.0.1
```

## Maintainer Notes

### Adding New Just Tasks

When adding new CI tasks to `justfiles/ci.just`:

1. ✅ **DO**: Make tasks self-contained
2. ✅ **DO**: Use explicit parameters (not env vars)
3. ✅ **DO**: Test locally before adding to workflows
4. ✅ **DO**: Document in this contract
5. ❌ **DON'T**: Depend on GitHub Actions-specific features
6. ❌ **DON'T**: Hard-code CI-specific paths

### Updating Tool Versions

Tool versions are specified in orchestrator workflows, not Just recipes:
- GitHub Actions: Workflow YAML installation steps
- Argo Workflows: Container image versions
- Local: Developer's installed tools

Keep minimum version requirements documented here.

```text

**Why this helps**:

- ✅ Makes expectations explicit for any CI system
- ✅ Documents migration path to Argo Workflows
- ✅ Helps contributors understand local testing
- ✅ Reference for future CI system integrations

## 3. Plan Update: Add Argo Migration Section

**File**: `.claude/plans/2025-11-18-github-actions-integration.md`

**Add new section after "Success Criteria" (around line 1240)**:

```markdown
## Future Migration Path: Argo Workflows

### Overview

The Justfile-centric architecture enables future migration to Argo Workflows (Kubernetes-native CI/CD) with minimal changes to core logic.

**Migration Risk**: ✅ **LOW** - All CI logic is in portable Just recipes

### Migration Readiness

**Already Argo-Compatible**:
- ✅ All CI logic in Just recipes (not workflow YAML)
- ✅ Container-based integration testing
- ✅ Standard CLI tools (shellcheck, ruff, lychee, etc.)
- ✅ GitHub releases abstracted to `gh` CLI
- ✅ CI contract documented (`.claude/ci-contract.md`)

**Will Need Adaptation**:
- ⚠️ Workflow orchestration syntax (GHA YAML → Argo templates)
- ⚠️ Trigger mechanisms (GHA webhooks → Argo Events)
- ⚠️ Secrets management (GHA secrets → Kubernetes secrets)
- ⚠️ PR labeling (GHA action → custom webhook handler)

### Argo Workflow Example

**Current GitHub Actions** (`.github/workflows/validate.yml`):
```yaml
lint-shell:
  runs-on: ubuntu-latest
  steps:
  - uses: actions/checkout@v4
  - name: Install Just
      uses: extractions/setup-just@v2
  - name: Run validation
      run: just lint-shell
```

**Future Argo Workflow** (`argo/validate.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: validate-
spec:
  templates:
  - name: lint-shell
    container:
      image: myorg/ci-tools:latest  # Pre-installed just, shellcheck
      command: [just, lint-shell]
      workingDir: /workspace
```

**Key Point**: Same `just lint-shell` command runs in both systems.

### Migration Timeline Estimate

**Phase 1: Preparation** (Already in this plan)
- Duration: Included in current implementation
- Tasks: Abstract GitHub releases, document CI contract
- Deliverables: `.claude/ci-contract.md`, improved Stage 6

**Phase 2: Argo Implementation** (Future, when ready)
- Duration: 1-2 weeks
- Tasks:
  - Set up Argo Workflows in Kubernetes cluster
  - Create CI tools container image
  - Translate workflows to Argo templates
  - Configure Argo Events for GitHub webhooks
  - Set up Kubernetes secrets

**Phase 3: Parallel Running** (Future)
- Duration: 1-2 weeks
- Tasks:
  - Run both GHA and Argo in parallel
  - Validate results match
  - Build confidence

**Phase 4: Migration** (Future)
- Duration: 1 week
- Tasks:
  - Switch primary CI to Argo
  - Keep GHA as backup
  - Decommission GHA after confidence period

**Total Future Effort**: 2-4 weeks (excluding current plan)

### References

- Full migration review: `.claude/plans/2025-11-18-argo-workflows-migration-review.md`
- CI contract: `.claude/ci-contract.md`
- Argo Workflows docs: https://argoproj.github.io/argo-workflows/

```text

## Implementation Checklist

### Stage 6 Updates (During Implementation)

- [ ] Split `release` recipe into `release-notes` and `github-release`
- [ ] Use `gh` CLI in `github-release` recipe
- [ ] Update `.github/workflows/release.yml` to install `gh` CLI
- [ ] Test locally: `just release-notes v0.0.1`
- [ ] Test locally with token: `GITHUB_TOKEN=... just github-release v0.0.1` (dry-run)

### New Documentation (During Implementation)

- [ ] Create `.claude/ci-contract.md` with environment requirements
- [ ] Document all Just tasks and their dependencies
- [ ] Document required secrets
- [ ] Add migration guide section

### Plan Updates (Now or During Implementation)

- [ ] Add "Future Migration Path: Argo Workflows" section to plan
- [ ] Reference migration review document
- [ ] Update Stage 6 code examples with improved recipes

## Benefits Summary

These improvements provide:

1. **Better testability** - Can test releases locally with `just release-notes`
2. **Clear contracts** - Documented expectations for any CI system
3. **Future-proof** - Ready for Argo Workflows migration with minimal effort
4. **No vendor lock-in** - `gh` CLI is more portable than GitHub Actions
5. **Better documentation** - CI contract helps contributors and future maintainers

## Timeline Impact

**Additional Time Required**: ⏱️ 2-4 hours total

- Stage 6 improvements: 1-2 hours
- CI contract documentation: 1-2 hours
- Plan updates: 30 minutes

**Value**: High - Makes system more testable, portable, and future-proof

## Conclusion

Your GitHub Actions plan is **already excellent** for Argo migration due to the Justfile-centric architecture. These improvements:

✅ Make GitHub releases testable locally
✅ Document CI contracts explicitly
✅ Add <2-4 hours to implementation
✅ Provide significant value for current use and future migration

**Recommendation**: Incorporate these changes into the current plan implementation.
