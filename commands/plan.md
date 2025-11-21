---
description: Create implementation plan for a feature
---

You are helping create implementation plans for software development tasks.

## When to Use

- User requests a plan (via "/plan" or "create a plan for...")
- User asks "how should I implement..."
- User needs technical design for a feature

## Process

### 1. Understand Requirements

Ask clarifying questions if the request is vague:

- What is the goal/outcome?
- Are there constraints (resources, dependencies)?
- Are there existing patterns/systems to follow?

**IMPORTANT**: Never estimate time or effort for tasks. Focus on technical approach and implementation details.

### 2. Gather Context

If a justfile exists with the `info` recipe, run it to understand:

```bash
just info 2>&1 || true
```

This provides (if available):

- Current branch and changes
- Available Just recipes
- Recent work
- Repository structure

Otherwise, gather context manually with:

```bash
git branch --show-current
git status --short
git log -5 --oneline --decorate
```

### 3. Create Structured Plan

Use the template from `.claude/prompts/plan.md`. The template uses JSON metadata to define implementation stages that can be extracted to git worktrees for parallel development.

**Key Elements**:

1. **JSON Metadata Block** - Defines metadata and stages:

```json metadata
{
  "plan_id": "YYYY-MM-DD-short-slug",
  "status": "draft",
  "stages": [
    {
      "id": "stage-1",
      "name": "Component/Feature Name",
      "branch": "feature/plan-id-stage-1",
      "worktree_path": "../worktrees/plan-id/stage-1",
      "status": "not-started",
      "depends_on": []
    }
  ]
}
```

1. **Human-Readable Body** - Standard markdown sections:
   - **Overview**: What and why (1-2 sentences)
   - **Requirements**: Functional and non-functional requirements
   - **Technical Approach**: Architecture, technologies, patterns
   - **Implementation Stages**: One section per stage with What/Why/How/Validation/TODO
   - **Testing Strategy**: Unit, integration, manual testing
   - **Deployment Plan**: Pre-deployment, staging, production, rollback
   - **Risks & Mitigations**: Risk table with mitigation strategies
   - **Dependencies**: Upstream/downstream impacts
   - **Success Criteria**: How we know it's done
   - **Overall TODO List**: High-level tracking across stages

**Stage Structure** (repeatable per component):

```markdown
### Stage N: [Component Name]

**Stage ID**: `stage-N`
**Branch**: `feature/plan-id-stage-N`
**Status**: Not Started
**Dependencies**: [List of stage IDs]

#### What
[What this stage builds - 1-2 sentences]

#### Why
[Why needed - business/technical rationale]

#### How
**Architecture**: [How component fits in system]
**Implementation Details**: [Technical approach, patterns]
**Files to Change**: Create/Modify/Delete lists
**Code Example**: [Key implementation snippets]

#### Validation
- [ ] Run tests
- [ ] Manual verification steps
- [ ] Integration checks

#### TODO for Stage N
- [ ] Specific actionable tasks
```

### 4. Save Plan

Save to `.claude/plans/YYYY-MM-DD-short-description.md`

### 5. Extract to Worktrees (Optional)

For plans with multiple independent stages, you can extract them to separate git worktrees.

**Using Just (Recommended)**:

```bash
# List all plans
just plan-ls

# Validate plan has proper metadata
just plan-validate .claude/plans/YYYY-MM-DD-feature.md

# List all stages
just plan-list .claude/plans/YYYY-MM-DD-feature.md

# Set up all worktrees
just plan-setup .claude/plans/YYYY-MM-DD-feature.md

# Or set up individual stage
just plan-stage .claude/plans/YYYY-MM-DD-feature.md stage-1

# Check status
just plan-status .claude/plans/YYYY-MM-DD-feature.md

# View all worktrees
just plan-worktrees
```

**Direct Script Usage** (stdlib only, no external dependencies):

```bash
uv run scripts/planworktree.py list .claude/plans/YYYY-MM-DD-feature.md
uv run scripts/planworktree.py setup-all .claude/plans/YYYY-MM-DD-feature.md
```

Each worktree gets:

- Its own branch: `feature/plan-id-stage-id`
- Isolated working directory: `../worktrees/plan-id/stage-id/`
- Symlink to plan: `.claude/plans/CURRENT_STAGE.md`

This allows parallel development of different components without branch conflicts.

See `skills/plan-worktree/SKILL.md` for detailed workflow.

## Best Practices

### Stage Organization

- **Each stage = discrete component**: Stages should be independently testable features/components
- **Minimize dependencies**: Design stages to be as parallel as possible
- **Clear boundaries**: Each stage should have well-defined inputs and outputs
- **Merge order**: Document dependency chains (stage-2 depends on stage-1, etc.)

### Plan Content

- Each stage should be actionable and specific
- Reference Just recipes where applicable ("Run `just test`")
- Include code examples for complex parts
- Consider backwards compatibility
- Think about edge cases and error handling
- Mention relevant existing code/patterns to follow
- **Never include time estimates or effort estimates** - focus only on what needs to be done and how

### Worktree Usage

- Use worktrees for large features with 3+ independent components
- Keep stages focused - better to have more smaller stages than fewer large ones
- Test each stage in isolation before merging
- Update stage status in plan frontmatter as work progresses
- Clean up worktrees after merging: `git worktree remove <path>`

## For Platform Engineering

- **K8s manifests**: Include resource limits, probes, labels, RBAC
- **Go code**: Error handling, context propagation, testing
- **Python code**: See project's Python Style Guide for detailed guidelines
  - Type hints required for all functions
  - Docstrings (Google/NumPy style) for all public functions
  - Prefer functions over classes (use classes only for data/state)
  - No lambdas - use named functions
  - Simple comprehensions only - prefer explicit for loops
  - Error handling with specific exceptions
- **Infrastructure**: Security, monitoring, rollback plans
