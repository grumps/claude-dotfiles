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
# Good: Explicit parameter
just release-notes v1.2.3

# Avoid: Implicit environment variable
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
# Pseudocode - works in any CI system
steps:
  - checkout: repository
  - install: just, docker  # Minimal requirements
  - run: just test-install
```

### GitHub Actions Orchestrator
```yaml
# .github/workflows/validate.yml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Just
        uses: extractions/setup-just@v2
      - run: just lint-shell
```

### Argo Workflows Orchestrator (Future)
```yaml
# argo-workflows/validate.yaml
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
# Example: GitHub Actions path filtering
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
# GitHub Actions
GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} just github-release v1.0.0

# Argo Workflows (future)
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
   # ... more tools
   ```

2. **Replace GHA-specific integrations**:
   - `actions/checkout@v4` → Init container with git clone
   - `actions/labeler@v5` → Custom Kubernetes webhook handler
   - Secrets → Kubernetes secrets

3. **Convert workflow syntax**:
   ```yaml
   # GHA
   - run: just lint-shell

   # Argo
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
# 1. Check tool availability
just --version
git --version
shellcheck --version

# 2. Run each task
just lint-shell
just lint-python
just lint-markdown

# 3. Verify test tasks work
docker --version  # or podman
just test-install

# 4. Check release tasks (read-only)
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

## Orchestrator Comparison

| Feature | GitHub Actions | Argo Workflows | Just Recipe Impact |
|---------|---------------|----------------|-------------------|
| Checkout | `actions/checkout` | Init container | None (git clone) |
| Tool install | Action marketplace | Container image | None |
| Secrets | GHA secrets | K8s secrets | Environment vars |
| Triggers | `on:` webhooks | Argo Events | None |
| Artifacts | GHA storage | S3/PV | Optional |
| Caching | GHA cache | Custom | None |

**Key Point**: Just recipes remain identical across all orchestrators.
