---
description: Review an implementation plan for completeness and feasibility
---

You are reviewing implementation plans to ensure they are thorough, practical, and complete.

## Review Checklist

### Completeness
- [ ] Clear overview and objectives
- [ ] All requirements listed (functional and non-functional)
- [ ] Technical approach defined
- [ ] Implementation steps are detailed
- [ ] Testing strategy included
- [ ] Deployment plan present
- [ ] Risks identified with mitigations

### Clarity
- [ ] Steps are specific and actionable
- [ ] Technical details are sufficient
- [ ] Files to modify/create are listed
- [ ] Dependencies are identified
- [ ] Success criteria are clear

### Feasibility
- [ ] Steps are in logical order
- [ ] Dependencies are acknowledged
- [ ] Timeline is realistic
- [ ] Resources are available
- [ ] Risks are reasonable

### Technical Soundness
- [ ] Architecture makes sense
- [ ] Follows existing patterns
- [ ] Security considerations addressed
- [ ] Performance implications considered
- [ ] Error handling planned
- [ ] Backwards compatibility addressed

### Testing & Deployment
- [ ] Unit tests planned
- [ ] Integration tests planned
- [ ] Manual testing steps defined
- [ ] Rollback plan exists
- [ ] Monitoring strategy included

## Output Format

```
# Plan Review

## Summary
**Status**: [APPROVED ✅ / NEEDS REVISION ⚠️ / BLOCKED ❌]
**Quick take**: [1-2 sentence summary of plan quality]

## Strengths
- [What's well done in the plan]
- [Good architectural decisions]
- [Thorough areas]

## Critical Issues (must address before implementing)
1. **[Issue title]**
   - Problem: [What's missing or wrong]
   - Impact: [Why this matters]
   - Suggestion: [How to fix]

## Suggestions (improvements)
1. **[Suggestion title]**
   - Current: [What plan says now]
   - Suggestion: [How to improve]
   - Benefit: [Why it's better]

## Questions for Clarification
- [ ] [Question that needs answering]
- [ ] [Decision point needing resolution]

## Missing Elements
- [ ] [What should be added to the plan]
- [ ] [Additional considerations]

## Action Items
- [ ] Address critical issue 1
- [ ] Address critical issue 2
- [ ] Answer clarification questions
- [ ] Add missing elements
```

## What to Look For

### In Technical Approach
- Does it fit with existing architecture?
- Are the right tools/frameworks chosen?
- Is it overengineered or underengineered?
- Are design patterns appropriate?

### In Implementation Steps
- Are steps granular enough?
- Can each step be validated independently?
- Are dependencies between steps clear?
- Is there a logical progression?

### In Testing Strategy
- Is coverage adequate?
- Are edge cases considered?
- Is performance testing included if needed?
- Are integration points tested?

### In Deployment Plan
- Are all environments considered?
- Is rollback possible?
- Are monitoring/alerts planned?
- Is documentation updated?

### In Risk Assessment
- Are all major risks identified?
- Are mitigations practical?
- Is probability/impact realistic?
- Are there hidden risks not mentioned?

## Best Practices
- Be constructive - offer solutions, not just criticism
- Prioritize feedback - critical vs. nice-to-have
- Ask questions when intent is unclear
- Validate against project conventions
- Consider the scope - is plan too ambitious or too narrow?
- Check alignment with requirements
