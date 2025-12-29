---
description: Review implementation plan for completeness and feasibility
argument-hint: [plan-file]
---

# Review Plan (rvp)

> Quick command: `/gdf:rvp [plan-file]` or `/rvp [plan-file]`
>
> Reviews implementation plans to ensure they are thorough, practical, and complete.

## Quick Reference

- **Usage**: `/rvp .claude/plans/2025-12-14-feature.md`
- **Arguments**:
  - `plan-file` (optional): Path to plan file to review
- **Output**: Review with status, issues, suggestions, and action items

## Error Handling

- **Plan file not found**: Shows error and lists available plans
- **Invalid plan format**: Shows error about missing required sections
- **No plans directory**: Shows error about missing `.claude/plans/`

## Review Implementation Plan

You are reviewing implementation plans to ensure they are thorough, practical, and complete.

## Workflow

### 1. Read the Plan

Thoroughly review the implementation plan file provided.

### 2. Apply Review Checklist

Evaluate the plan against these dimensions:

**Completeness**: Overview, requirements, technical approach, testing, deployment, risks
**Clarity**: Specific steps, sufficient details, clear dependencies and success criteria
**Feasibility**: Logical order, realistic scope, available resources
**Technical Soundness**: Architecture, patterns, security, performance, error handling
**Testing & Deployment**: Unit/integration tests, rollback plan, monitoring

### 3. Identify Issues

**Critical**: Must address before implementation (missing requirements, technical flaws, security risks)
**Suggestions**: Improvements and optimizations (better approaches, edge cases)
**Questions**: Clarifications needed (unclear intent, decision points)
**Missing**: Elements to add (monitoring, error handling, documentation)

### 4. Generate Review

Use the template from:

@../prompts/review-plan.md

Include:

- Status (APPROVED/NEEDS REVISION/BLOCKED)
- Strengths (what's well done)
- Critical issues with impact and suggestions
- Improvement suggestions
- Questions for clarification
- Missing elements
- Action items

## Review Principles

- Be constructive - offer solutions, not just criticism
- Prioritize feedback - critical vs. nice-to-have
- Ask questions when intent is unclear
- Validate against project conventions
- Consider scope - too ambitious or too narrow?
- Check alignment with requirements

See the output template above for the expected format.
