---
description: Create implementation plan for a feature
argument-hint: [description]
---

# Plan (pln)

> Quick command: `/gdf:pln [description]` or `/pln [description]`
>
> Creates a structured implementation plan for software development tasks.

## Quick Reference

- **Usage**: `/pln create user authentication`
- **Arguments**:
  - `description`: Brief description of what to plan
- **Output**: Structured plan in `.claude/plans/YYYY-MM-DD-description.md`
- **Standards**: References `skills/planning/SKILL.md`

## Error Handling

- **Vague requirements**: Asks clarifying questions
- **Plan directory missing**: Creates `.claude/plans/` directory
- **Git not available**: Shows error about git requirement

## Create Implementation Plan

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

Reference the planning skill for methodology, structure, best practices, and platform engineering guidelines:

@../skills/planning/SKILL.md

### 4. Create Structured Plan

Use the template from:

@../prompts/plan.md

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
