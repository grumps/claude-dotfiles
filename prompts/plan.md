# Implementation Plan: [TITLE]

<!--
This template uses JSON metadata to define extractable implementation stages.
Each stage can be developed in its own git worktree for parallel development.

To set up worktrees: just plan-setup .claude/plans/[this-file].md
See skills/plan-worktree/SKILL.md for details.
-->

```json metadata
{
  "plan_id": "YYYY-MM-DD-short-slug",
  "created": "YYYY-MM-DD",
  "author": "[NAME]",
  "status": "draft",
  "stages": [
    {
      "id": "stage-1",
      "name": "[Component/Feature Name]",
      "branch": "feature/[plan-id]-[stage-id]",
      "worktree_path": "../worktrees/[plan-id]/[stage-id]",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "stage-2",
      "name": "[Component/Feature Name]",
      "branch": "feature/[plan-id]-[stage-id]",
      "worktree_path": "../worktrees/[plan-id]/[stage-id]",
      "status": "not-started",
      "depends_on": ["stage-1"]
    }
  ]
}
```

## Overview
[1-2 sentences describing what we're building and why it matters]

## Requirements

### Functional Requirements
- [ ] Requirement 1
- [ ] Requirement 2

### Non-Functional Requirements
- [ ] Security: [requirements]
- [ ] Scalability: [targets]

## Technical Approach

### Architecture
[Describe how components fit together, data flow, etc.]

### Technologies
- **Language**: [Go/Python/etc.]
- **Frameworks**: [libraries, tools]
- **Infrastructure**: [K8s, databases, etc.]

### Design Patterns
[Which patterns we're using and why]

### Existing Code to Follow
[Reference similar implementations in the codebase]

## Implementation Stages

Each stage below corresponds to a stage definition in the frontmatter and can be extracted to its own worktree.

### Stage 1: [Component/Feature Name]

**Stage ID**: `stage-1`
**Branch**: `feature/[plan-id]-stage-1`
**Status**: Not Started
**Dependencies**: None

#### What
[Description of what this stage builds - the component/feature in 1-2 sentences]

#### Why
[Why this stage is needed - the business/technical rationale]

#### How

**Architecture**:
[How this component fits into the overall system]

**Implementation Details**:
- Detail 1: [Technical approach]
- Detail 2: [Design pattern to use]
- Detail 3: [Integration points]

**Files to Change**:
- Create: `path/to/new/file.go`
- Modify: `path/to/existing/file.py`
- Delete: `path/to/obsolete/file.js`

**Code Example**:
```go
// Example of key implementation
func NewFeature() {
    // ...
}
```

#### Validation
- [ ] Run `just test-stage-1` or `just test`
- [ ] Manual test: [specific steps to verify]
- [ ] Integration test: [verify with other components]

#### TODO for Stage 1
- [ ] Specific actionable task 1
- [ ] Specific actionable task 2
- [ ] Specific actionable task 3

---

### Stage 2: [Component/Feature Name]

**Stage ID**: `stage-2`
**Branch**: `feature/[plan-id]-stage-2`
**Status**: Not Started
**Dependencies**: stage-1

[Repeat structure above for each stage]

---

## Testing Strategy

### Unit Tests
**Coverage Goal**: [e.g., 80%]
**Key Scenarios**:
- Test case 1
- Test case 2

### Integration Tests
**Scenarios**:
- End-to-end workflow
- Error conditions
- Edge cases

### Manual Testing
**Checklist**:
- [ ] Test step 1
- [ ] Test step 2

## Deployment Plan

### Pre-deployment
- [ ] Run `just validate` (all checks pass)
- [ ] Update documentation
- [ ] Create pull request
- [ ] Code review approved

### Staging Deployment
- [ ] Deploy to staging: `just deploy-staging`
- [ ] Smoke tests pass
- [ ] Security scan pass

### Production Deployment
- [ ] Deploy: `just deploy-production`
- [ ] Monitor error rates
- [ ] Verify functionality

### Rollback Plan
If issues detected:
1. `just rollback-production`
2. Investigate issues
3. Fix and redeploy

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Database migration fails] | Medium | High | [Test on staging first, have rollback script ready] |

## Dependencies

### Upstream Dependencies
- [ ] Dependency 1 (blocked by: [ticket])
- [ ] Dependency 2

### Downstream Impact
- Team/System 1: [how they're affected]
- Team/System 2: [notification needed]

## Open Questions

- [ ] Question 1 requiring decision
- [ ] Question 2 needing clarification

## Success Criteria

- [ ] All tests pass
- [ ] Security scan clean
- [ ] Documentation complete
- [ ] Deployed to production
- [ ] Monitoring shows healthy metrics

## Overall TODO List

High-level tracking across all stages. Stage-specific TODOs are in each stage section above.

### Pre-Implementation
- [ ] Review and approve plan
- [ ] Clarify open questions
- [ ] Set up worktrees for stages (run `just plan-setup [plan-id]`)

### Implementation (per stage)
- [ ] Stage 1: [Component Name] - See Stage 1 TODO above
- [ ] Stage 2: [Component Name] - See Stage 2 TODO above
- [ ] Stage N: [Component Name] - See Stage N TODO above

### Integration & Testing
- [ ] Merge all stage branches
- [ ] Run full integration tests
- [ ] Address any conflicts or integration issues

### Documentation & Deployment
- [ ] Update README.md
- [ ] Update CHANGELOG.md
- [ ] Create pull request
- [ ] Deploy to staging
- [ ] Deploy to production

## References

- Design doc: [link]
- Related tickets: [PLAT-123, PLAT-456]
- Similar implementation: [link to code]
