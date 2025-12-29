# GDF Plugin Commands Reference

This document provides detailed reference for all commands in the gdf (Grumps Dotfiles) plugin.

## Command Overview

All commands support dual invocation:

- **Namespaced**: `/gdf:command` (always works, prevents conflicts)
- **Short form**: `/command` (works unless another command has the same name)

## Commands by Category

### Planning & Review

#### `/gdf:pln` (or `/pln`) - Plan

**Description**: Create structured implementation plan for a feature

**Usage**: `/pln [description]`

**Arguments**:

- `description` (optional): Brief description of what to plan

**Example**:

```text
/pln create user authentication
```

**Output**: Creates `.claude/plans/YYYY-MM-DD-description.md` with structured plan

**See also**: `commands/planning/pln.md`

---

#### `/gdf:rvp` (or `/rvp`) - Review Plan

**Description**: Review implementation plan for completeness and feasibility

**Usage**: `/rvp [plan-file]`

**Arguments**:

- `plan-file` (optional): Path to plan file to review

**Example**:

```text
/rvp .claude/plans/2025-12-14-feature.md
```

**Output**: Comprehensive review with status, issues, suggestions, and action items

**See also**: `commands/planning/rvp.md`

---

### Code Review

#### `/gdf:rvc` (or `/rvc`) - Review Code

**Description**: Review staged code changes with automated checks

**Usage**: `/rvc`

**Prerequisites**: Changes must be staged (`git add`)

**Example**:

```text
git add .
/rvc
```

**Output**: Code review with security, performance, and style checks

**See also**: `commands/review/rvc.md`

---

### Git Workflows

#### `/gdf:commit` (or `/commit`) - Commit

**Description**: Generate conventional commit message for staged changes

**Usage**: `/commit`

**Prerequisites**: Changes must be staged (`git add`)

**Example**:

```text
git add .
/commit
```

**Output**: Conventional commit message following the format: `type(scope): description`

**See also**: `commands/git/commit.md`

---

#### `/gdf:ppr` (or `/ppr`) - Prepare PR

**Description**: Prepare feature branch for PR with linear history workflow

**Usage**: `/ppr [base-branch]`

**Arguments**:

- `base-branch` (optional): Target branch for PR (defaults to main/master)

**Example**:

```text
/ppr
/ppr develop
```

**Output**: Guides through rebase, squash, and PR creation workflow

**See also**: `commands/git/ppr.md`, `docs/git-workflow.md`

---

### Feedback Workflow

#### `/gdf:fba` (or `/fba`) - Feedback Add

**Description**: Start inline feedback workflow with checkpoint commit

**Usage**: `/fba`

**Example**:

```text
/fba
```

**Output**: Creates checkpoint commit and shows files to review. You add feedback manually in your editor.

**Next step**: Edit files to add feedback comments, then use `/fbr` to review

**See also**: `commands/feedback/fba.md`

---

#### `/gdf:fbr` (or `/fbr`) - Feedback Review

**Description**: Review, respond to, and resolve inline feedback

**Usage**: `/fbr`

**Prerequisites**: Must have added feedback after running `/fba`

**Example**:

```text
/fbr
```

**Output**: Parsed feedback with responses and resolution tracking

**See also**: `commands/feedback/fbr.md`

---

#### `/gdf:fbc` (or `/fbc`) - Feedback Clean

**Description**: Strip all inline feedback comments from code and markdown files

**Usage**: `/fbc`

**Example**:

```text
/fbc
```

**Output**: Removes all feedback markers from files, optionally archives them

**See also**: `commands/feedback/fbc.md`

---

### Development Tools

#### `/gdf:just-help` (or `/just-help`) - Just Help

**Description**: Get help with Just command runner and available recipes

**Usage**: `/just-help [recipe]`

**Arguments**:

- `recipe` (optional): Specific recipe to get help for

**Example**:

```text
/just-help
/just-help test
```

**Output**: Lists available Just recipes or provides help for specific recipe

**See also**: `commands/just/just-help.md`

---

#### `/gdf:helm-render` (or `/helm-render`) - Helm Render

**Description**: Render and validate Helm charts with custom values

**Usage**: `/helm-render [chart] [values-file]`

**Arguments**:

- `chart` (optional): Helm chart to render
- `values-file` (optional): Custom values file

**Example**:

```text
/helm-render
/helm-render bitnami/nginx
/helm-render bitnami/nginx values.yaml
```

**Output**: Rendered Kubernetes manifests with validation

**See also**: `commands/helm/helm-render.md`, `docs/helm-guide.md`

---

## Quick Reference Table

| Command | Short | Description | Arguments |
|---------|-------|-------------|-----------|
| `/gdf:pln` | `/pln` | Create implementation plan | `[description]` |
| `/gdf:rvp` | `/rvp` | Review implementation plan | `[plan-file]` |
| `/gdf:rvc` | `/rvc` | Review staged code changes | - |
| `/gdf:commit` | `/commit` | Generate commit message | - |
| `/gdf:ppr` | `/ppr` | Prepare PR with linear history | `[base-branch]` |
| `/gdf:fba` | `/fba` | Add inline feedback | - |
| `/gdf:fbr` | `/fbr` | Review inline feedback | - |
| `/gdf:fbc` | `/fbc` | Clean inline feedback | - |
| `/gdf:just-help` | `/just-help` | Get Just help | `[recipe]` |
| `/gdf:helm-render` | `/helm-render` | Render Helm charts | `[chart] [values-file]` |

## Common Workflows

### Complete Feature Development

```bash
# 1. Plan the feature
/pln add rate limiting to API

# 2. Review the plan
/rvp .claude/plans/2025-12-14-rate-limiting.md

# 3. Implement the feature...
# (make your changes)

# 4. Review your code
git add .
/rvc

# 5. Commit the changes
/commit

# 6. Prepare for PR
/ppr
```

### Code Review with Feedback

```bash
# 1. Create checkpoint for feedback
/fba

# 2. Add feedback comments manually in your editor
# Example: // FEEDBACK(reviewer): Consider edge case X

# 3. Review and respond to feedback
/fbr

# 4. Clean up feedback markers when done
/fbc
```

### Helm Chart Exploration

```bash
# 1. Get help with Helm integration
/just-help helm

# 2. Render a chart to see what it creates
/helm-render bitnami/nginx

# 3. Render with custom values
/helm-render bitnami/nginx my-values.yaml
```

## Error Handling

Each command includes comprehensive error handling. Common scenarios:

- **No staged changes**: Commands like `/rvc` and `/commit` will show an error and usage instructions
- **Git not available**: Git-dependent commands will error if git is not in PATH
- **Missing files**: File-based commands will list available alternatives
- **Invalid arguments**: Commands will show proper usage and examples

Use `/help` in Claude Code to see all available commands with their descriptions.

## Plugin Management

### Check Plugin Installation

```bash
ls -la ~/.claude/plugins/gdf
```

### View Plugin Metadata

```bash
cat ~/.claude/plugins/gdf/plugin.json
```

### Use Namespaced Invocation

If a command conflicts with another plugin or user command, use the namespaced form:

```text
/gdf:pln   # instead of /pln
/gdf:rvc   # instead of /rvc
```

## See Also

- **Plugin README**: `.claude/plugins/gdf/README.md` - Plugin overview
- **Git Workflow**: `docs/git-workflow.md` - Linear history workflow
- **Helm Guide**: `docs/helm-guide.md` - Helm integration guide
- **Skills**: `skills/` - AI skill guides for planning, reviewing, etc.
- **Prompts**: `prompts/` - Output format templates
