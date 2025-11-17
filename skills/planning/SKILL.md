# Planning Skill

You are helping create implementation plans for software development tasks.

## When to Use
- User requests a plan (via "/plan" or "create a plan for...")
- User asks "how should I implement..."
- User needs technical design for a feature

## Process

### 1. Understand Requirements
Ask clarifying questions if the request is vague:
- What is the goal/outcome?
- Are there constraints (time, resources, dependencies)?
- Are there existing patterns/systems to follow?

### 2. Gather Context
Run `just info` to understand:
- Current branch and changes
- Available Just recipes
- Recent work
- Repository structure

### 3. Create Structured Plan
Use this format:

```
# Implementation Plan: [TITLE]

## Overview
[1-2 sentences: what we're building and why]

## Requirements
- [ ] Functional requirement 1
- [ ] Functional requirement 2
- [ ] Non-functional (performance, security, etc.)

## Technical Approach
**Architecture**: [How components fit together]
**Technologies**: [Languages, frameworks, tools]
**Patterns**: [Design patterns, existing code to follow]

## Implementation Steps

### Step 1: [Name]
**What**: [What we're building]
**Why**: [Why this step is necessary]
**How**: [Technical details, code snippets]
**Files**: [Files to create/modify]
**Validation**: `just test-feature` or manual test steps

### Step 2: [Name]
...

## Testing Strategy
- **Unit tests**: [What to test, coverage goals]
- **Integration tests**: [What scenarios]
- **Manual testing**: [Steps to verify]

## Deployment Checklist
- [ ] Run `just validate` (lint + tests pass)
- [ ] Update documentation
- [ ] Create pull request
- [ ] Deploy to staging
- [ ] Smoke test in staging
- [ ] Deploy to production
- [ ] Monitor for errors

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk description] | Low/Med/High | Low/Med/High | [How to prevent/handle] |

## Open Questions
- [ ] Question needing answer before proceeding
- [ ] Decision point requiring input
```

### 4. Save Plan
Save to `.claude/plans/YYYY-MM-DD-short-description.md`

## Best Practices
- Each step should be actionable and specific
- Reference Just recipes where applicable ("Run `just test`")
- Include code examples for complex parts
- Consider backwards compatibility
- Think about edge cases and error handling
- Mention relevant existing code/patterns to follow

## For Platform Engineering
- **K8s manifests**: Include resource limits, probes, labels, RBAC
- **Go code**: Error handling, context propagation, testing
- **Python code**: See [Python Style Guide](../../../docs/python-style-guide.md) for detailed guidelines
  - Type hints required for all functions
  - Docstrings (Google/NumPy style) for all public functions
  - Prefer functions over classes (use classes only for data/state)
  - No lambdas - use named functions
  - Simple comprehensions only - prefer explicit for loops
  - Error handling with specific exceptions
- **Infrastructure**: Security, monitoring, rollback plans
