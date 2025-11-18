# Argo Workflows Migration Compatibility Review

**Plan Reviewed**: `.claude/plans/2025-11-18-github-actions-integration.md`
**Review Date**: 2025-11-18
**Reviewer**: Claude Code
**Migration Target**: Argo Workflows (Kubernetes-native workflow engine)

## Executive Summary

✅ **Migration Risk: LOW** - The Justfile-centric architecture is **excellent** for future Argo Workflows migration. The plan minimizes vendor lock-in by keeping all CI logic in Just recipes with GitHub Actions as thin orchestration wrappers.

**Key Strengths**:
- All CI logic in portable Just recipes
- Container-based integration testing (maps directly to Argo)
- Standard CLI tools that run anywhere
- Minimal GitHub Actions marketplace dependencies

**Areas Requiring Adaptation** (not blockers):
- GitHub-specific integrations (PR comments, releases API, auto-labeler)
- Trigger mechanisms and path filtering
- Secrets management approach

## Detailed Analysis

### ✅ Migration-Friendly Decisions

#### 1. **Justfile-Centric Architecture** (EXCELLENT)
**Current Approach**:
```just
# All logic in justfiles/ci.just
lint-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  shellcheck --severity=warning $(find . -name "*.sh")
```

**Argo Migration Path**:
```yaml
# Argo Workflow - same Just recipe, different orchestrator
- name: lint-shell
  container:
    image: ubuntu:latest
    command: [just, lint-shell]
```

**Assessment**: ✅ Perfect portability. Just recipes work identically in any container runtime.

#### 2. **Container-Based Integration Testing** (EXCELLENT)
**Current Approach**:
- BATS tests in `archlinux:latest` container
- `just test-install` uses Docker/Podman

**Argo Migration Path**:
- Argo Workflows is container-native
- Same containers, different orchestrator
- Can add more complex container dependencies easily

**Assessment**: ✅ Direct mapping. Argo's container-first model is ideal for this.

#### 3. **Standard CLI Tools** (EXCELLENT)
**Tools Used**:
- ShellCheck, shfmt, ruff, mypy, lychee, git-cliff, cocogitto

**Assessment**: ✅ All tools are standard binaries that run in any Linux container. No GitHub Actions-specific tooling.

#### 4. **Minimal GitHub Actions Marketplace Dependencies** (GOOD)
**Current Dependencies**:
- `actions/checkout@v4` - Standard git clone (easy to replace)
- `extractions/setup-just@v2` - Just installation (can bake into container)
- `astral-sh/setup-uv@v4` - uv installation (can bake into container)
- `actions/labeler@v5` - **GitHub-specific** (needs alternative)
- `softprops/action-gh-release@v2` - **GitHub-specific** (needs alternative)

**Assessment**: ✅ Most actions are tool installers. Can create custom container images with tools pre-installed.

### ⚠️ Areas Requiring Adaptation

#### 1. **GitHub-Specific Integrations** (Medium Impact)

**Current GitHub-Specific Features**:

| Feature | Current Implementation | Argo Alternative | Effort |
|---------|----------------------|------------------|--------|
| PR Comments | GitHub Actions API | Argo Events + GitHub API | Low |
| Auto-labeler | `actions/labeler@v5` | Custom webhook handler | Medium |
| GitHub Releases | `softprops/action-gh-release@v2` | Just recipe + GitHub API | Low |
| Branch Protection | GitHub native | External enforcement | Medium |
| Status Checks | GitHub native | Custom reporting | Medium |

**Recommendations**:
1. **Abstract GitHub releases into Just recipe** (enables local testing):
   ```just
   # Create release (works locally and in any CI)
   create-release TAG NOTES:
     #!/usr/bin/env bash
     gh release create {{TAG}} \
       --title "Release {{TAG}}" \
       --notes "{{NOTES}}" \
       install.sh uninstall.sh
   ```

2. **Use Argo Events** for webhook handling when migrating
3. **Move PR validation logic to Just recipes** where possible

#### 2. **Workflow Triggers and Path Filtering** (Low Impact)

**Current Approach**:
```yaml
on:
  pull_request:
    paths:
      - 'install.sh'
      - 'uninstall.sh'
```

**Argo Alternative**:
- Argo Events with sensors and triggers
- Path filtering in event sources
- Conditional workflow templates

**Recommendation**:
- Document trigger requirements in a separate config file
- Keep path filtering logic simple and declarable
- Consider using Argo Events when migrating

#### 3. **Secrets Management** (Low Impact)

**Current Approach**:
- GitHub Actions secrets (`${{ secrets.GITHUB_TOKEN }}`)

**Argo Alternative**:
- Kubernetes secrets
- External secrets operator
- Vault integration

**Recommendation**:
- Document required secrets in plan
- Use environment variables in Just recipes (already doing this)
- Secrets are passed from orchestrator to container

#### 4. **Artifact Storage** (Very Low Impact)

**Current Approach**:
- GitHub Actions artifact storage (not heavily used)
- Release assets via GitHub Releases

**Argo Alternative**:
- S3/Minio for artifacts
- PV/PVC for temporary storage

**Recommendation**:
- Current plan doesn't rely heavily on artifacts ✅
- If needed, add S3 upload to Just recipe

### 📋 Migration-Ready Checklist

#### Already Migration-Friendly ✅
- [x] All CI logic in Just recipes (not workflow YAML)
- [x] Container-based integration testing
- [x] Standard CLI tools (no proprietary dependencies)
- [x] Minimal vendor-specific features
- [x] Local-CI parity via Just recipes

#### Recommended Improvements

**High Priority (Include in Current Plan)**:
- [ ] **Abstract GitHub releases into Just recipe**
  - Move `gh release create` logic to `justfiles/ci.just`
  - Make release creation testable locally
  - Example:
    ```just
    # Release management (works with any orchestrator)
    github-release TAG:
      #!/usr/bin/env bash
      set -euo pipefail
      NOTES=$(git-cliff --config cliff.toml --unreleased --tag "{{TAG}}" --strip all)
      gh release create "{{TAG}}" \
        --title "Release {{TAG}}" \
        --notes "$NOTES" \
        install.sh uninstall.sh
    ```

**Medium Priority (Nice to Have)**:
- [ ] **Document workflow contract**
  - Create `.claude/ci-contract.md` explaining orchestrator expectations
  - List required environment variables
  - Document trigger requirements
  - Example sections:
    - Required secrets (GITHUB_TOKEN, etc.)
    - Expected inputs (commit SHA, PR number, etc.)
    - Output format expectations

- [ ] **Create CI container images**
  - Pre-install Just, ShellCheck, ruff, etc. in custom image
  - Reduces setup time in both GHA and Argo
  - Example `Dockerfile`:
    ```dockerfile
    FROM ubuntu:latest
    RUN apt-get update && apt-get install -y \
      just shellcheck git
    # ... more tools
    ```

**Low Priority (Future Work)**:
- [ ] **Path filtering configuration file**
  - Extract path filters to `.claude/ci-paths.yaml`
  - Use in both GHA and Argo
  - Reduces duplication

## Argo Workflows Conceptual Mapping

### Current GitHub Actions Structure
```yaml
# .github/workflows/validate.yml
jobs:
  lint-shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Just
        uses: extractions/setup-just@v2
      - name: Run validation
        run: just lint-shell
```

### Equivalent Argo Workflow
```yaml
# argo-workflows/validate.yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: validate-
spec:
  entrypoint: validate
  templates:
  - name: validate
    steps:
    - - name: lint-shell
        template: just-task
        arguments:
          parameters:
          - name: task
            value: lint-shell

  - name: just-task
    inputs:
      parameters:
      - name: task
    container:
      image: myorg/ci-tools:latest  # Custom image with Just pre-installed
      command: [just]
      args: ["{{inputs.parameters.task}}"]
      workingDir: /workspace
      volumeMounts:
      - name: workspace
        mountPath: /workspace
```

**Key Differences**:
- Argo uses container images (can pre-install tools)
- Argo uses parameters instead of workflow inputs
- Argo has native DAG support (better than GHA's `needs:`)
- Source code checkout handled differently (init containers or artifacts)

**Similarities**:
- ✅ Same Just recipes execute identically
- ✅ Same exit codes indicate success/failure
- ✅ Same tool versions in containers

## Migration Effort Estimate

### Phase 1: Preparation (Include in Current Plan)
**Effort**: 2-4 hours

- Abstract GitHub releases to Just recipe
- Document CI contract (environment, secrets, triggers)
- Create custom CI container image (optional but recommended)

### Phase 2: Argo Workflows Implementation (Future)
**Effort**: 1-2 weeks

- Set up Argo Workflows in Kubernetes cluster
- Configure Argo Events for GitHub webhooks
- Translate workflow YAML to Argo templates
- Set up artifact storage (S3/Minio)
- Configure Kubernetes secrets
- Test end-to-end workflows

### Phase 3: Migration (Future)
**Effort**: 1 week

- Run both systems in parallel
- Validate Argo results match GHA results
- Switch primary CI to Argo
- Keep GHA as backup initially
- Decommission GHA after confidence period

**Total Estimated Effort**: 2-3 weeks (not including current plan improvements)

## Recommendations Summary

### ✅ Approve Current Plan With Minor Additions

The current plan is **excellent** for Argo migration. Recommend adding:

1. **Abstract GitHub-specific operations** (2-3 hours):
   - Move GitHub releases to Just recipe in Stage 6
   - Use `gh` CLI in recipe instead of GitHub Action
   - Makes releases testable locally

2. **Document CI contract** (1 hour):
   - Create `.claude/ci-contract.md`
   - List required environment variables
   - Document trigger expectations
   - Helps both GHA and future Argo implementation

3. **Add migration notes to plan** (30 minutes):
   - Add "Future Migration" section to plan
   - Reference this review document
   - Keep migration path visible

### 🎯 Key Principles to Maintain

As you implement the current plan, maintain these principles:

1. **Keep all logic in Just recipes** - Never put CI logic in workflow YAML
2. **Use standard tools** - Avoid GitHub Actions-specific marketplace actions
3. **Test locally** - If it doesn't work with `just <command>`, it's too coupled
4. **Document contracts** - Make orchestrator expectations explicit
5. **Use containers** - Container-based testing maps directly to Argo

### ❌ Anti-Patterns to Avoid

Do NOT do these (would hurt migration):

1. ❌ Put business logic in workflow YAML (keep it in Just recipes)
2. ❌ Use GitHub Actions expressions heavily (`${{ }}` syntax)
3. ❌ Rely on GitHub Actions cache/artifacts (use external storage if needed)
4. ❌ Use GitHub Actions composite actions for core logic
5. ❌ Hard-code GitHub-specific APIs in shell scripts (use `gh` CLI for abstraction)

## Conclusion

**Migration Risk Assessment**: ✅ **LOW**

The Justfile-centric architecture is **exactly right** for avoiding vendor lock-in. The plan demonstrates excellent architectural discipline:

- ✅ Separation of concerns (orchestration vs. logic)
- ✅ Local-CI parity (testability)
- ✅ Standard tools and containers
- ✅ Minimal vendor-specific features

**Recommendation**: **APPROVE** the current plan with the minor additions above (abstract GitHub releases, document CI contract). These additions take minimal time and provide significant value for both current use and future migration.

When you're ready to migrate to Argo Workflows in a few months, you'll have:
- Proven, tested Just recipes that work anywhere
- Clear documentation of orchestrator requirements
- Container-based integration tests ready for Kubernetes
- Minimal GitHub-specific code to adapt

**Next Steps**:
1. Implement current GitHub Actions plan as-is
2. Add the 3 recommended improvements (releases abstraction, CI contract, migration notes)
3. In 2-3 months when ready for Argo: Follow Phase 2/3 migration plan above

## References

### Argo Workflows
- Argo Workflows Documentation: https://argoproj.github.io/argo-workflows/
- Argo Events (GitHub webhooks): https://argoproj.github.io/argo-events/
- Argo Workflows Examples: https://github.com/argoproj/argo-workflows/tree/master/examples

### Migration Patterns
- Avoiding CI/CD Vendor Lock-in: https://www.thoughtworks.com/insights/blog/infrastructure/ci-cd-portability
- Container-First CI/CD: https://www.cncf.io/blog/2021/03/09/container-native-ci-cd/
