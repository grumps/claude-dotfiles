---
description: Create implementation plan for a feature
---

# Create Implementation Plan

You are helping create implementation plans for software development tasks.

## Workflow

### 1. Understand Requirements

Ask clarifying questions if the request is vague:

- What is the goal/outcome?
- Are there constraints (resources, dependencies)?
- Are there existing patterns/systems to follow?

**IMPORTANT**: Never estimate time or effort for tasks. Focus on technical approach and implementation details.

### 2. Gather Context

If a justfile exists with the `info` recipe:

```bash
just info 2>&1 || true
```

Otherwise, gather context manually:

```bash
git branch --show-current
git status --short
git log -5 --oneline --decorate
```

### 3. Apply Planning Standards

Reference `skills/planning/SKILL.md` for:

- Planning methodology
- Plan structure and sections
- Best practices
- Platform engineering guidelines

### 4. Create Structured Plan

Use the template from `prompts/plan.md`.

The template includes:

- JSON metadata for worktree extraction
- Overview, requirements, technical approach
- Implementation stages (What/Why/How/Validation)
- Testing strategy, deployment plan
- Risks, dependencies, success criteria

### 5. Save Plan

Save to `.claude/plans/YYYY-MM-DD-short-description.md`

### 6. Worktree Extraction (Optional)

For multi-stage plans, extract to git worktrees for parallel development.

See `skills/plan-worktree/SKILL.md` for detailed workflow.

**Quick commands**:

```bash
just plan-setup .claude/plans/YYYY-MM-DD-feature.md
just plan-status .claude/plans/YYYY-MM-DD-feature.md
```

## Planning Principles

- Each stage should be actionable and specific
- Reference Just recipes where applicable
- Include code examples for complex parts
- **Never estimate time or effort** - focus on what and how
- Design stages to be as parallel as possible
- Document dependency chains between stages

See `skills/planning/SKILL.md` for detailed methodology and best practices.
