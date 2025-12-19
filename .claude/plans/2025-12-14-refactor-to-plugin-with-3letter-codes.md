# Implementation Plan: Refactor Slash Commands to Plugin with Short Command Names

## Overview

Refactor existing custom slash commands from subdirectory-based organization to a formal plugin structure with short command names for frequently used commands (e.g., `fba` for feedback-add, `pln` for plan) while keeping descriptive names for less common ones (e.g., `commit`, `helm-render`), comprehensive argument hints, quick references, and full inline help documentation.

## Requirements

- [x] Convert 10 existing slash commands to plugin structure
- [x] Implement short names for frequently used commands (3-letter codes)
- [x] Keep descriptive names for less frequently used commands
- [x] Add argument hints to all commands that accept parameters
- [x] Include quick reference sections in command documentation
- [x] Maintain all existing functionality
- [x] Provide dual invocation patterns (`/gdf:cmd` and `/cmd`)
- [x] Ensure commands appear in `/help` with clear descriptions
- [x] Create well-structured plugin.json with metadata
- [x] Update documentation and installer

## Technical Approach

**Architecture**: Convert from `.claude/commands/{category}/{command}.md` to `.claude/plugins/gdf/commands/{category}/{abbreviation}.md` structure

**Plugin Namespace**: `gdf` (grumps dotfiles)

**Technologies**:

- Plugin system (native Claude Code)
- Markdown with YAML frontmatter
- JSON for plugin metadata

**Patterns**: Follow Claude Code plugin structure as documented in reference/slash-commands.md:100-280

## Implementation Stages

### Stage 1: Create Plugin Structure

**What**: Set up the base plugin directory structure and metadata

**Why**: Establishes the foundation for the plugin and enables namespace discovery

**How**:

```bash
# Create plugin directory structure
.claude/plugins/gdf/
├── plugin.json
├── README.md
└── commands/
    ├── feedback/
    ├── git/
    ├── helm/
    ├── just/
    ├── planning/
    └── review/
```

**plugin.json structure**:

```json
{
  "name": "gdf",
  "version": "1.0.0",
  "description": "Grumps dotfiles - personal workflow commands for git, planning, feedback, and development",
  "author": "grumps",
  "commands": [
    "fba", "fbr", "fbc",
    "commit", "ppr",
    "helm-render",
    "just-help",
    "pln", "rvp",
    "rvc"
  ],
  "changelog": "Initial plugin release with 10 workflow commands"
}
```

**Note**: Version managed via tooling during release (e.g., `bump2version` or similar).

**README.md structure**:

```markdown
# GDF Plugin - Grumps Dotfiles

Personal workflow commands for development, git workflows, planning, and code review.

## Commands

### Feedback Workflow
- `/gdf:fba` - Feedback add: Start inline feedback workflow
- `/gdf:fbr` - Feedback review: Review and respond to feedback
- `/gdf:fbc` - Feedback clean: Remove all feedback comments

### Git Workflows
- `/gdf:commit` - Commit: Generate conventional commit message
- `/gdf:ppr` - Prepare PR: Prepare feature branch for PR

### Helm
- `/gdf:helm-render` - Helm render: Explore and validate Helm charts

### Just
- `/gdf:just-help` - Just help: Get help with Just command runner

### Planning
- `/gdf:pln` - Plan: Create implementation plan
- `/gdf:rvp` - Review plan: Review implementation plan

### Code Review
- `/gdf:rvc` - Review code: Review staged changes

## Usage

Commands can be invoked with or without the namespace:
- `/gdf:fba` (explicit namespace)
- `/fba` (short form, if no conflicts)
```

**Files**:

- `.claude/plugins/gdf/plugin.json`
- `.claude/plugins/gdf/README.md`
- `.claude/plugins/gdf/commands/` (subdirectories)

**Validation**:

```bash
# Check structure
ls -la .claude/plugins/gdf/
cat .claude/plugins/gdf/plugin.json
```

### Stage 2: Define Command Abbreviations and Metadata

**What**: Create mapping of old names to new 3-letter codes with comprehensive metadata

**Why**: Establishes consistent naming scheme and ensures all commands have proper help documentation

**How**:

**Command Mapping**:

| Old Name | Category | New Name | Full Name | Arguments | Rationale |
|----------|----------|----------|-----------|-----------|-----------|
| feedback-add | feedback | fba | Feedback Add | none | Frequent use |
| feedback-review | feedback | fbr | Feedback Review | none | Frequent use |
| feedback-clean | feedback | fbc | Feedback Clean | none | Frequent use |
| commit | git | commit | Commit | none | Already short |
| prepare-pr | git | ppr | Prepare PR | [base-branch] | Frequent use |
| helm-render | helm | helm-render | Helm Render | [chart] [values-file] | Less frequent |
| just-help | just | just-help | Just Help | [recipe] | Less frequent |
| plan | planning | pln | Plan | [description] | Frequent use |
| review-plan | planning | rvp | Review Plan | [plan-file] | Frequent use |
| review-code | review | rvc | Review Code | none | Frequent use |

**Standard Frontmatter Template**:

```yaml
---
description: [Short description for /help output]
argument-hint: [Optional argument syntax]
allowed-tools: [Tool restrictions if needed]
---
```

**Files**: Planning document (this file) - no code changes yet

**Validation**: Review mapping table for consistency and completeness

### Stage 3: Migrate Feedback Commands

**What**: Convert feedback workflow commands (fba, fbr, fbc) to plugin structure

**Why**: Feedback commands are self-contained and good starting point

**How**:

**For each command (feedback-add.md → fba.md)**:

1. Copy existing content to new location
2. Add/update frontmatter with description and argument-hint
3. Add Quick Reference section at top
4. Preserve all existing documentation

**Example - fba.md structure**:

```markdown
---
description: Start inline feedback workflow with checkpoint commit
argument-hint: (no arguments)
---

# Feedback Add (fba)

> Quick command: `/gdf:fba` or `/fba`
>
> Starts inline feedback workflow by creating checkpoint commit and showing
> files to review. You add feedback manually in your editor.

## Quick Reference

- **Usage**: `/fba`
- **Purpose**: Create checkpoint before manual code review
- **Output**: Shows changed files and feedback format examples
- **Next Step**: Edit files to add feedback, then use `/fbr` to review

## Error Handling

- **No changes to commit**: Shows error message and exits
- **Git not available**: Shows error about git requirement
- **Already in feedback session**: Warns about existing checkpoint

## When to Use
[existing content...]

[rest of existing documentation...]
```

**Files**:

- `.claude/plugins/gdf/commands/feedback/fba.md`
- `.claude/plugins/gdf/commands/feedback/fbr.md`
- `.claude/plugins/gdf/commands/feedback/fbc.md`

**Validation**:

```bash
# Check files exist
ls -la .claude/plugins/gdf/commands/feedback/

# Verify frontmatter is valid YAML
head -10 .claude/plugins/gdf/commands/feedback/fba.md
```

### Stage 4: Migrate Git Commands

**What**: Convert git workflow commands (commit, ppr) to plugin structure

**Why**: Git commands may have arguments that need proper argument-hint configuration

**How**:

**commit.md** (no arguments):

```markdown
---
description: Generate conventional commit message for staged changes
argument-hint: (no arguments)
---

# Commit

> Quick command: `/gdf:commit` or `/commit`
>
> Analyzes staged changes and generates a conventional commit message
> following repository standards.

## Quick Reference

- **Usage**: `/commit`
- **Prerequisites**: Changes must be staged (`git add`)
- **Output**: Commit message following Conventional Commits format
- **Standards**: References `skills/commits/SKILL.md`

## Error Handling

- **No staged changes**: Shows error message and usage instructions
- **Not in git repository**: Shows error about git requirement
- **Detached HEAD state**: Warns user about current git state

[existing content...]
```

**ppr.md** (with optional argument):

```markdown
---
description: Prepare feature branch for PR with linear history
argument-hint: [base-branch]
---

# Prepare PR (ppr)

> Quick command: `/gdf:ppr [base-branch]` or `/ppr [base-branch]`
>
> Prepares feature branch for pull request by ensuring linear history,
> running tests, and creating PR with generated summary.

## Quick Reference

- **Usage**: `/ppr` or `/ppr main`
- **Arguments**:
  - `base-branch` (optional): Target branch for PR (defaults to main/master)
- **Prerequisites**: Feature branch with commits
- **Output**: Created pull request with summary and test plan

## Examples

```bash
# Use default base branch
/ppr

# Specify base branch
/ppr develop
```

[existing content...]

```text

**Files**:
- `.claude/plugins/gdf/commands/git/commit.md`
- `.claude/plugins/gdf/commands/git/ppr.md`

**Validation**:
```bash
# Verify argument hints are clear
grep "argument-hint:" .claude/plugins/gdf/commands/git/*.md
```

### Stage 5: Migrate Remaining Commands

**What**: Convert helm, just, planning, and review commands (helm-render, just-help, pln, rvp, rvc)

**Why**: Complete the migration with all remaining commands

**How**:

**Pattern for commands with arguments**:

**helm-render.md**:

```markdown
---
description: Explore and validate Helm charts
argument-hint: [chart] [values-file]
---

# Helm Render

> Quick command: `/gdf:helm-render [chart] [values-file]` or `/helm-render [chart] [values-file]`

## Quick Reference

- **Usage**: `/helm-render` or `/helm-render bitnami/nginx` or `/helm-render bitnami/nginx values.yaml`
- **Arguments**:
  - `chart` (optional): Chart name (e.g., bitnami/nginx)
  - `values-file` (optional): Custom values file path
- **Purpose**: Explore chart values, validate configurations, render manifests

## Examples

```bash
# Interactive exploration
/helm-render

# Show chart values
/helm-render bitnami/nginx

# Validate with custom values
/helm-render bitnami/nginx my-values.yaml
```

[existing content...]

```text

**just-help.md**:

```markdown
---
description: Get help with Just command runner and available recipes
argument-hint: [recipe]
---

# Just Help

> Quick command: `/gdf:just-help [recipe]` or `/just-help [recipe]`

## Quick Reference

- **Usage**: `/just-help` or `/just-help test`
- **Arguments**:
  - `recipe` (optional): Specific recipe to get help for
- **Purpose**: List available Just recipes or get help for specific recipe

[existing content...]
```

**pln.md**:

```markdown
---
description: Create implementation plan for a feature
argument-hint: [description]
---

# Plan (pln)

> Quick command: `/gdf:pln [description]` or `/pln [description]`

## Quick Reference

- **Usage**: `/pln create user authentication`
- **Arguments**:
  - `description`: Brief description of what to plan
- **Output**: Structured plan in `.claude/plans/YYYY-MM-DD-description.md`
- **Standards**: References `skills/planning/SKILL.md`

[existing content...]
```

**rvp.md**:

```markdown
---
description: Review implementation plan for completeness and feasibility
argument-hint: [plan-file]
---

# Review Plan (rvp)

> Quick command: `/gdf:rvp [plan-file]` or `/rvp [plan-file]`

## Quick Reference

- **Usage**: `/rvp .claude/plans/2025-12-14-feature.md`
- **Arguments**:
  - `plan-file` (optional): Path to plan file to review
- **Output**: Review with status, issues, suggestions, and action items

[existing content...]
```

**rvc.md**:

```markdown
---
description: Review staged code changes with automated checks
argument-hint: (no arguments)
---

# Review Code (rvc)

> Quick command: `/gdf:rvc` or `/rvc`

## Quick Reference

- **Usage**: `/rvc`
- **Prerequisites**: Changes must be staged (`git add`)
- **Output**: Code review with security, performance, and style checks

[existing content...]
```

**Files**:

- `.claude/plugins/gdf/commands/helm/helm-render.md`
- `.claude/plugins/gdf/commands/just/just-help.md`
- `.claude/plugins/gdf/commands/planning/pln.md`
- `.claude/plugins/gdf/commands/planning/rvp.md`
- `.claude/plugins/gdf/commands/review/rvc.md`

**Validation**:

```bash
# Count total commands
find .claude/plugins/gdf/commands -name "*.md" | wc -l
# Should be 10

# Verify all have descriptions
find .claude/plugins/gdf/commands -name "*.md" -exec grep -L "description:" {} \;
# Should be empty
```

### Stage 6: Update Installer and Documentation

**What**: Update install.sh and documentation to reference plugin structure

**Why**: Users need to know about the new plugin and how to use abbreviated commands

**How**:

**Update install.sh**:

```bash
# Change from:
# ln -sf "$REPO_DIR/commands" "$TARGET_DIR/commands"

# To:
# Create plugins directory if needed
mkdir -p "$TARGET_DIR/plugins"

# Check for conflicts with existing user commands
echo "Checking for command conflicts..."
CONFLICTS=""
for cmd in fba fbr fbc ppr pln rvp rvc; do
  if [ -f "$TARGET_DIR/commands/$cmd.md" ]; then
    CONFLICTS="$CONFLICTS $cmd"
  fi
done

if [ -n "$CONFLICTS" ]; then
  echo "⚠️  Warning: Found conflicting user commands:$CONFLICTS"
  echo "   Plugin commands will take precedence over user commands with same names."
  echo "   Consider renaming your user commands or using namespaced invocation (/gdf:cmd)."
fi

# Remove existing symlink if present
if [ -L "$TARGET_DIR/plugins/gdf" ]; then
  echo "Updating existing gdf plugin symlink..."
  rm "$TARGET_DIR/plugins/gdf"
fi

# Symlink the individual plugin
ln -sf "$REPO_DIR/.claude/plugins/gdf" "$TARGET_DIR/plugins/gdf"

# Note: Keep backward compatibility if needed
if [ -d "$TARGET_DIR/commands" ]; then
  echo "Note: Old commands/ directory detected. After verifying plugin works, you can remove it."
fi
```

**Check for internal command cross-references**:

```bash
# Find all references to old command names in new plugin commands
grep -r "/feedback-\|/review-\|/prepare-pr\|/helm-render\|/just-help" \
  .claude/plugins/gdf/commands/

# Update any found references to use new names
```

**Update docs/git-workflow.md** (and any other docs referencing commands):

```markdown
# Before:
Use `/feedback-add` to start review

# After:
Use `/gdf:fba` (or `/fba`) to start review

# Add abbreviation reference table
## Command Quick Reference

| Command | Full Name | Description |
|---------|-----------|-------------|
| fba | Feedback Add | Start inline feedback workflow |
| fbr | Feedback Review | Review and respond to feedback |
| fbc | Feedback Clean | Remove feedback comments |
| commit | Commit | Generate commit message |
| ppr | Prepare PR | Prepare feature branch for PR |
| helm-render | Helm Render | Explore and validate Helm charts |
| just-help | Just Help | Get help with Just recipes |
| pln | Plan | Create implementation plan |
| rvp | Review Plan | Review implementation plan |
| rvc | Review Code | Review staged changes |
```

**Create new documentation**:

- `.claude/plugins/gdf/COMMANDS.md` - Detailed command reference
- Update root README.md to mention plugin structure

**Files**:

- `install.sh`
- `docs/git-workflow.md`
- `.claude/plugins/gdf/COMMANDS.md`
- `README.md`

**Validation**:

```bash
# Test installer in clean environment
./install.sh
ls -la ~/.claude/plugins/gdf/

# Verify symlink points to correct location
readlink ~/.claude/plugins/gdf
# Should point to repo's .claude/plugins/gdf

# Verify plugin is discoverable
claude
> /plugin
# Should show gdf plugin
```

### Stage 7: Clean Up Old Structure

**What**: Remove old commands/ directory and update git

**Why**: Eliminate confusion and maintain single source of truth

**How**:

1. Verify plugin commands work via `/help`
2. Test several commands to ensure functionality
3. Remove old structure:

```bash
# Remove old command files
git rm -r commands/

# Commit the migration
git add .claude/plugins/gdf/
git add install.sh docs/
git commit -m "refactor: migrate slash commands to gdf plugin with optimized naming

- Convert 10 commands to plugin structure under .claude/plugins/gdf/
- Use short names for frequent commands: fba, fbr, fbc, ppr, pln, rvp, rvc
- Keep descriptive names for less frequent: commit, helm-render, just-help
- Add argument hints and quick references to all commands
- Update installer to use plugin directory
- Add command reference documentation
- Support dual invocation: /gdf:cmd and /cmd

Commands maintain full functionality with improved discoverability via /help."
```

**Files**:

- Delete `commands/` directory
- Stage all changes in `.claude/plugins/gdf/`

**Validation**:

```bash
# Verify old commands directory is gone
ls commands/
# Should error: No such file or directory

# Verify new structure
ls .claude/plugins/gdf/commands/
# Should show feedback, git, helm, just, planning, review

# Test in fresh shell
claude
> /help
# Should show gdf plugin commands

> /fba
# Should work

> /gdf:commit
# Should work
```

## Testing Strategy

### Unit Testing (Manual)

**Test each command individually**:

```bash
# For each command, test:
1. /help shows command with description
2. Command invokes successfully
3. Argument hints appear in autocomplete
4. Documentation is accessible
5. Both /gdf:cmd and /cmd work (if no conflicts)
```

**Example test plan for fba**:

```bash
# 1. Check help
/help | grep fba
# Expected: Shows description

# 2. Invoke command
/fba
# Expected: Creates checkpoint, shows files

# 3. Test namespace
/gdf:fba
# Expected: Same behavior as /fba

# 4. Check argument hint
# Type "/fba" and press tab
# Expected: Shows "(no arguments)"
```

### Integration Testing

**Test command workflows**:

```bash
# Test feedback workflow
/fba          # Start feedback
# Edit files manually
/fbr          # Review feedback
/fbc          # Clean feedback

# Test git workflow
git add .
/commit       # Generate commit
/ppr          # Prepare PR

# Test planning workflow
/pln add dark mode feature
/rvp .claude/plans/2025-12-14-add-dark-mode-feature.md
```

### Validation Checklist

- [ ] All 10 commands appear in `/help`
- [ ] All commands have descriptions
- [ ] All commands with arguments have argument-hint
- [ ] All commands have Quick Reference section
- [ ] Plugin namespace works (`/gdf:cmd`)
- [ ] Short form works (`/cmd`) when no conflicts
- [ ] Installer creates correct symlinks (individual plugin, not whole directory)
- [ ] Installer detects and warns about command conflicts
- [ ] Documentation is updated and accurate
- [ ] Old commands/ directory is removed
- [ ] No broken references in docs or code
- [ ] All internal command cross-references updated to new names

## Deployment Checklist

- [ ] Run all manual tests
- [ ] Verify `/help` output
- [ ] Test in clean environment
- [ ] Review all command files for typos
- [ ] Check all frontmatter is valid YAML
- [ ] Verify installer works
- [ ] Check installer conflict warnings work correctly
- [ ] Update CLAUDE.md if it references old commands (e.g., `/feedback-add` → `/fba`)
- [ ] Validate plugin.json syntax: `python3 -m json.tool .claude/plugins/gdf/plugin.json`
- [ ] Commit with conventional commit message
- [ ] Test after install in production environment

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Name conflicts with other plugins/commands | Low | Medium | Use namespace prefix `/gdf:` explicitly when needed |
| Short codes not memorable for less frequent users | Low | Low | Add Quick Reference in each command and COMMANDS.md reference table |
| Users have muscle memory for old names | Medium | Low | Dual invocation supports both namespaced and short forms |
| Installer breaks existing setups | Low | High | Test in clean environment, provide migration notes |
| Frontmatter parsing errors | Low | Medium | Validate all YAML before committing, test with `/help` |
| Documentation out of sync | Medium | Medium | Update all docs in same commit as code changes |

## Success Criteria

- [ ] All 10 commands successfully migrated to plugin structure
- [ ] Commands appear in `/help` with clear descriptions
- [ ] Argument hints work for all commands with parameters
- [ ] Quick Reference sections provide fast orientation
- [ ] Both namespace and short forms work as expected
- [ ] Installer successfully deploys plugin
- [ ] Documentation is complete and accurate
- [ ] No regressions in command functionality
- [ ] Old commands/ directory removed
- [ ] Clean commit history with conventional message

## Decisions Made

- [x] **Installer symlink strategy**: Symlink individual plugin (`.claude/plugins/gdf`) not whole directory
- [x] **Conflict detection**: Installer warns about conflicting user commands
- [x] **Cross-references**: Update internal command references to new names
- [x] **Version management**: Use existing tooling for version bumps during release
- [x] **Error handling**: Add error handling sections to command documentation
- [x] **Argument hints**: Show syntax in hint, examples in Quick Reference
- [x] **Versioning**: Start with 1.0.0, use semantic versioning
- [x] **Metadata**: Keep plugin.json simple for now

## Notes

- Plugin structure is native to Claude Code, no external dependencies
- Balanced naming strategy: short codes for frequent use, descriptive names for clarity
- Frequently used commands (feedback, planning, review) get 3-letter codes for speed
- Less frequent commands (commit, helm-render, just-help) keep descriptive names
- Quick Reference sections compensate for non-obvious abbreviations
- Dual invocation pattern provides flexibility for users
- Installer symlinks individual plugin for flexibility with other plugins
- Installer detects conflicts with existing user commands
- Error handling documented for common failure scenarios
- Version managed via existing tooling (bump during release)
- No performance concerns with 10 commands (well under SlashCommand tool's 15k char budget)
- Installer is idempotent and safe to re-run
