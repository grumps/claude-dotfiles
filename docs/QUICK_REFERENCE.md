# Claude Dotfiles - Quick Reference

One-page reference for all commands and workflows.

## Quick Start (5 Minutes)

```bash
# 1. Install Just
brew install just  # or see README for other platforms

# 2. Clone dotfiles
git clone <repo> ~/.claude-dotfiles

# 3. Set up your project
cd your-project
~/.claude-dotfiles/install.sh

# 4. Configure justfile (implement lint and test recipes)
# Edit justfile - add your linters and test commands

# 5. Start using
just validate  # Run lint + test
```

## Slash Commands Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/plan <feature>` | Create implementation plan | Starting new feature |
| `/review-plan <file>` | Review plan completeness | After generating plan |
| `/review-code` | Review staged changes | Before committing |
| `/commit` | Generate commit message | When ready to commit |
| `/update-docs` | Update documentation | After code changes |
| `/just-help` | Get Just recipe help | Learning Just commands |
| `/helm-render` | Work with Helm charts | Rendering/validating charts |

## Just Recipes Reference

### Core Recipes (Available Everywhere)

```bash
just validate      # Run lint + test (pre-commit runs this)
just info          # Show repo info and status
just check-clean   # Verify no uncommitted changes
just --list        # See all available recipes
```

### Documentation Recipes (Optional)

```bash
just check-docs    # Check if docs need updating
just verify-docs   # Verify links and examples
just doc-coverage  # Generate doc coverage report
```

### Custom Recipes (You Define)

```bash
just lint          # REQUIRED - Run your linters
just test          # REQUIRED - Run your tests
just lint-for-claude  # OPTIONAL - Lint output for Claude
just test-for-claude  # OPTIONAL - Test output for Claude
```

## Git Hooks Reference

### pre-commit

- **Runs**: `just validate` (lint + test)
- **Blocks**: Commits that fail validation
- **Bypass**: `git commit --no-verify` (not recommended)

### post-commit

- **Runs**: Documentation check
- **Blocks**: Nothing (just reminds)
- **Disable**: `export CHECK_DOCS_ENABLED=false`

### prepare-commit-msg (Optional)

- **Runs**: Only if made executable
- **Generates**: Commit message in editor
- **Enable**: `chmod +x .git/hooks/prepare-commit-msg`

## Scripts Reference

### Helm Chart Exploration (User-level tooling)

```bash
# Explore third-party charts
just helm-explore bitnami/nginx          # Chart info + values + README
just helm-show bitnami/nginx             # Show all available values

# Validate and render
just helm-validate bitnami/nginx my-values.yaml
just helm-render bitnami/nginx my-values.yaml
just helm-test bitnami/nginx my-values.yaml  # Validate + render

# Compare configurations
just helm-compare bitnami/nginx current.yaml proposed.yaml

# Repository management
just helm-add-repo bitnami https://charts.bitnami.com/bitnami
just helm-update

# Quick workflows
just helm-watch bitnami/nginx my-values.yaml  # Auto re-render on changes
```

**See**: [Helm Guide](./helm-guide.md) for comprehensive documentation

## Development Workflow

1. `/plan` → 2. Code → 3. `just validate` → 4. `/review-code` → 5. `/commit` → 6. Push

**Commands**:

```bash
/plan implement feature    # Generate plan
# ... implement code ...
just validate             # Run lint + test
git add .                 # Stage changes
/review-code             # Get Claude review
/commit                  # Generate commit message
git commit -m "..."      # Commit
git push                 # Push to remote
```

## File Structure

**Global** (`~/.claude-dotfiles/`):

- `commands/` → Symlinked to `~/.claude/commands/` (Claude reads from here)
- `justfiles/` → Imported by project justfiles
- `hooks/`, `prompts/`, `skills/` → Templates copied/used during install

**Per-project**:

- `justfile` → Imports from `~/.claude-dotfiles/justfiles/_base.just`
- `.claude/plans/` → Generated plans stored here
- `.git/hooks/pre-commit` → Runs `just validate`

## Common Patterns

### Starting a New Feature

```text
/plan add user authentication
↓
Review plan
↓
Create branch: git checkout -b feature/auth
↓
Implement phase 1
↓
just validate
↓
git add . && /review-code
↓
/commit && git commit
↓
Repeat for remaining phases
```

### Quick Validation Before Commit

```bash
just validate  # Faster than waiting for hook
```

### Generate Commit Message

```text
/commit  # Copy output
```

or

```bash
git commit  # Auto-generate if hook enabled
```

### Update Documentation

```text
/update-docs  # After code changes
```

or

```bash
just check-docs  # Check if needed
```

## Customization Quick Guide

### Per-Project

**justfile** - Add custom recipes

```just
deploy:
  kubectl apply -f k8s/
```

**context.yaml** - Add project context

```yaml
project:
  name: "My API"
conventions:
  commit_scopes:
    - api
    - auth
```

**prompts/** - Customize output

```bash
cp .claude/prompts/commit.md .claude/prompts/commit-custom.md
# Edit for your team
```

### Team-Wide

1. Fork repository
2. Add team skills to `skills/team/`
3. Customize commands in `commands/`
4. Add shared recipes to `justfiles/`
5. Document in team README

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "just: command not found" | Install Just: <https://just.systems> |
| Recipe not found | `just --list` - check available recipes |
| Validation failing | `just lint` and `just test` separately to debug |
| Hook not running | `chmod +x .git/hooks/pre-commit` |
| Slash commands not working | Verify `.claude/commands/` exists |
| Need to skip validation | `git commit --no-verify` (use sparingly) |

## Environment Variables

```bash
# Disable doc check reminder
export CHECK_DOCS_ENABLED=false

# Custom justfile location (advanced)
export JUST_FILE_PATH=/path/to/justfile
```

## Keyboard Shortcuts & Tips

### In Claude

- Type `/` to see available commands
- Use `/plan` liberally - even for small features
- `/review-code` before every commit
- `/update-docs` after significant changes

### In Terminal

```bash
just v  # Alias for validate (if you set it up)
just l  # Alias for lint
just t  # Alias for test

# Add to your justfile:
alias v := validate
alias l := lint
alias t := test
```

## Integration Checklist

- [ ] Just installed
- [ ] Dotfiles cloned to `~/.claude-dotfiles`
- [ ] Ran `install.sh` in project
- [ ] Implemented `lint` recipe in justfile
- [ ] Implemented `test` recipe in justfile
- [ ] Tested: `just validate` passes
- [ ] Verified: `.claude/commands/` exists
- [ ] Verified: Git hooks are executable
- [ ] Tried: `/plan test feature` in Claude
- [ ] Tried: `/review-code` in Claude

## Learning Path

1. **Day 1**: Install and basic usage
   - Install Just and dotfiles
   - Run `install.sh`
   - Try `just validate`

2. **Day 2**: Slash commands
   - Create a plan: `/plan`
   - Review code: `/review-code`
   - Generate commit: `/commit`

3. **Week 1**: Customize
   - Add custom Just recipes
   - Customize prompts
   - Set up context.yaml

4. **Week 2**: Advanced
   - Use plan worktrees
   - Team customization
   - CI/CD integration

## Links

- [README](../README.md) - Full documentation
- [Architecture](ARCHITECTURE.md) - System design
- [Workflows](../examples/workflows.md) - Detailed examples
- [Contributing](../CONTRIBUTING.md) - Development guide

---

**Pro Tip**: Keep this file open in a browser tab for quick reference while working!

Print-friendly version: Add `?print-pdf` to URL if using a documentation viewer.
